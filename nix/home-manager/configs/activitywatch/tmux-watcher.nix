# ActivityWatch watcher for tmux -- records which session/window/pane is in front.
#
# Why this exists: awatcher's window watcher only ever sees the terminal emulator
# ("kitty"), so every hour spent in tmux collapses into one undifferentiated app.
# This watcher splits that time by tmux session, window and running command, which
# is the axis the work is actually organised along.
#
# tmux itself cannot know whether its terminal has keyboard focus, so heartbeats
# are gated on two buckets that awatcher already maintains: the window bucket must
# show a terminal in front, and the AFK bucket must not say afk. Without those
# gates an attached-but-backgrounded session would bill hours of browser time to
# tmux. Blind spot of that approach: a second terminal window running something
# other than tmux is indistinguishable from the one that is, so a heartbeat can be
# attributed to tmux while the front terminal is a plain shell.
{
  pkgs,
  config,
  ...
}: let
  # Client and server speak a version-specific protocol, so this has to be the
  # very tmux the user's sessions run under, not a second copy from pkgs.
  tmuxPackage = config.programs.tmux.package;

  settings = {
    tmux = "${tmuxPackage}/bin/tmux";
    host = "127.0.0.1";
    port = 5600;
    # Poll interval, and how long a gap the server may bridge when merging two
    # heartbeats carrying identical data. pulsetime > poll keeps a steady pane
    # from fragmenting into one event per tick.
    poll = 10;
    pulsetime = 30;
    # Window-bucket app names that count as "a terminal is in front". Extend when
    # adding a terminal emulator.
    terminals = ["kitty" "alacritty" "foot" "wezterm" "ghostty" "org.wezfurlong.wezterm" "xterm"];
    # A window event older than this means awatcher is dead or wedged; treat that
    # as unknown focus and stop recording rather than trusting a stale app name.
    focusMaxAge = 60;
  };

  watcher = pkgs.writeScriptBin "aw-watcher-tmux" ''
    #!${pkgs.python3}/bin/python3
    """Report the foreground tmux session/window/pane to ActivityWatch."""
    import json
    import os
    import socket
    import subprocess
    import sys
    import time
    import urllib.error
    import urllib.request
    from datetime import datetime, timezone

    CFG = json.loads(${builtins.toJSON (builtins.toJSON settings)})
    TERMINALS = set(CFG["terminals"])
    HOSTNAME = socket.gethostname()
    BASE = f"http://{CFG['host']}:{CFG['port']}/api/0"
    BUCKET = f"aw-watcher-tmux_{HOSTNAME}"
    WINDOW_BUCKET = f"aw-watcher-window_{HOSTNAME}"
    AFK_BUCKET = f"aw-watcher-afk_{HOSTNAME}"


    def log(msg):
        print(msg, file=sys.stderr, flush=True)


    def request(method, path, payload=None):
        data = json.dumps(payload).encode() if payload is not None else None
        req = urllib.request.Request(
            BASE + path,
            data=data,
            method=method,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read()
            return json.loads(body) if body else None


    def last_event(bucket):
        try:
            events = request("GET", f"/buckets/{bucket}/events?limit=1")
        except urllib.error.HTTPError as err:
            if err.code == 404:  # watcher never ran on this host
                return None
            raise
        return events[0] if events else None


    def tmux(*args):
        result = subprocess.run(
            [CFG["tmux"], *args], capture_output=True, text=True, timeout=5
        )
        # Non-zero covers the common "no server running" case, which is not an error.
        return result.stdout.strip() if result.returncode == 0 else None


    def foreground_pane():
        """Active pane of the session whose client was used most recently."""
        clients = tmux("list-clients", "-F", "#{client_activity}\t#{client_session}")
        if not clients:
            return None
        newest = max(clients.splitlines(), key=lambda line: int(line.split("\t")[0]))
        session = newest.split("\t")[1]
        fmt = "\t".join([
            "#{session_name}",
            "#{window_index}",
            "#{window_name}",
            "#{pane_current_command}",
            "#{pane_current_path}",
        ])
        line = tmux("display-message", "-p", "-t", session, "-F", fmt)
        if not line:
            return None
        name, index, window, command, path = line.split("\t")
        home = os.path.expanduser("~")
        pretty = f"~{path[len(home):]}" if path.startswith(home) else path
        return {
            "session": name,
            "window": f"{index}:{window}",
            "command": command,
            "path": pretty,
            "project": os.path.basename(path) or path,
            "title": f"{name} > {window} > {command}",
        }


    def blocked():
        """Reason not to record right now, or None to go ahead."""
        event = last_event(AFK_BUCKET)
        if event and event["data"].get("status") == "afk":
            return "afk"

        event = last_event(WINDOW_BUCKET)
        if event is None:
            return "no window events"
        stamp = datetime.fromisoformat(event["timestamp"])
        age = (datetime.now(timezone.utc) - stamp).total_seconds()
        if age > CFG["focusMaxAge"]:
            return f"window bucket stale ({int(age)}s)"
        app = event["data"].get("app", "")
        if app not in TERMINALS:
            return f"{app!r} in front"
        return None


    def ensure_bucket():
        try:
            request("POST", f"/buckets/{BUCKET}", {
                "client": "aw-watcher-tmux",
                "type": "app.terminal.activity",
                "hostname": HOSTNAME,
            })
        except urllib.error.HTTPError as err:
            if err.code != 304:  # 304 == bucket already exists
                raise


    def heartbeat(data):
        request("POST", f"/buckets/{BUCKET}/heartbeat?pulsetime={CFG['pulsetime']}", {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "duration": 0,
            "data": data,
        })


    def main():
        # aw-server may still be starting; the bucket is created lazily so a slow
        # server delays the first heartbeat instead of crash-looping the unit.
        ready = False
        while True:
            try:
                if not ready:
                    ensure_bucket()
                    ready = True
                pane = foreground_pane()
                if pane is not None and blocked() is None:
                    heartbeat(pane)
            except Exception as err:  # noqa: BLE001 -- a poll failure must not end the loop
                log(f"aw-watcher-tmux: {err!r}")
                ready = False
            time.sleep(CFG["poll"])


    if __name__ == "__main__":
        main()
  '';
in {
  home.packages = [watcher];

  systemd.user.services.activitywatch-watcher-tmux = {
    Unit = {
      Description = "ActivityWatch watcher 'tmux'";
      # Focus gating reads buckets that only awatcher fills, so this watcher is
      # useless outside a graphical session and follows it in and out.
      After = ["graphical-session.target" "activitywatch.service"];
      Requisite = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${watcher}/bin/aw-watcher-tmux";
      Restart = "on-failure";
      RestartSec = "10";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
