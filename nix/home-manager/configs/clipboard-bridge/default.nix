# Clipboard bridge — paste screenshots taken on a desktop machine into terminal
# programs (Claude Code, Codex) running over SSH on a headless server.
#
# Why this exists: Claude Code reads the clipboard by shelling out to `xclip` /
# `wl-paste` on whatever host it runs on. On a headless server there is no
# clipboard, so Ctrl+V finds nothing. Upstream `clipaste` solves this but its
# daemon is hard-gated to macOS/Windows, so this module reimplements the same
# HTTP contract with per-OS backends and stays wire-compatible with it.
#
# Two roles:
#   source — machines with a real clipboard (macbook, nixos desktop). Runs a
#            daemon serving the clipboard image on 127.0.0.1:<port>.
#   sink   — the headless remote (home-server). Installs commands named `xclip`
#            and `wl-paste` that shadow the real ones, so an unmodified Claude
#            Code transparently gets the desktop's screenshot on Ctrl+V.
#
# Transport is an SSH reverse tunnel on a loopback TCP port, which needs no
# privileges on either end. A unix socket would isolate better, but sshd creates
# forwarded sockets owned by root rather than by the connecting user, so making
# one usable requires StreamLocalBindMask in sshd_config — i.e. root on the sink.
# Caveat of TCP: the forwarded port is reachable by any local account on the sink
# while a session is open. Push-to-file would avoid both problems if that ever
# matters more than the convenience of an on-demand pull.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.clipboardBridge;

  # Each backend reports clipboard MIME types on stdout (probe) and writes PNG
  # bytes to stdout (fetch). Attribute values stay lazy, so the darwin-only
  # pngpaste is never evaluated on Linux.
  backends = {
    macos = {
      # pngpaste exits non-zero when no image is present, and converts macOS'
      # native TIFF screenshots to PNG.
      probe = "${pkgs.pngpaste}/bin/pngpaste - >/dev/null 2>&1 && echo image/png";
      fetch = "${pkgs.pngpaste}/bin/pngpaste -";
    };
    wayland = {
      probe = "${pkgs.wl-clipboard}/bin/wl-paste --list-types";
      fetch = "${pkgs.wl-clipboard}/bin/wl-paste --type image/png";
    };
    x11 = {
      probe = "${pkgs.xclip}/bin/xclip -selection clipboard -t TARGETS -o";
      fetch = "${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -o";
    };
  };

  backend = backends.${cfg.source.backend};

  # Serves the clipaste HTTP contract:
  #   GET /clipboard/type  -> {"type":"image"} when an image is on the clipboard
  #   GET /clipboard/image -> raw PNG bytes
  sourceDaemon = pkgs.writeScriptBin "clipboard-bridge" ''
    #!${pkgs.python3}/bin/python3
    """Serve the local clipboard image over HTTP for remote terminal pastes."""
    import json
    import subprocess
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    PROBE_CMD = ${builtins.toJSON backend.probe}
    FETCH_CMD = ${builtins.toJSON backend.fetch}
    PORT = ${toString cfg.port}


    def has_image():
        try:
            done = subprocess.run(PROBE_CMD, shell=True, capture_output=True, timeout=5)
        except subprocess.TimeoutExpired:
            return False
        return b"image/" in done.stdout


    def get_image():
        try:
            done = subprocess.run(FETCH_CMD, shell=True, capture_output=True, timeout=15)
        except subprocess.TimeoutExpired:
            return b""
        return done.stdout if done.returncode == 0 else b""


    class Handler(BaseHTTPRequestHandler):
        def respond(self, code, content_type, body):
            self.send_response(code)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/clipboard/type":
                kind = "image" if has_image() else "text"
                self.respond(200, "application/json", json.dumps({"type": kind}).encode())
            elif self.path == "/clipboard/image":
                data = get_image()
                if data:
                    self.respond(200, "image/png", data)
                else:
                    self.respond(404, "text/plain", b"no image on clipboard\n")
            else:
                self.respond(404, "text/plain", b"not found\n")

        # Silence per-request logging; this runs constantly in the background.
        def log_message(self, *args):
            pass


    if __name__ == "__main__":
        ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
  '';

  # Keeps one reverse tunnel alive per sink. ExitOnForwardFailure makes ssh quit
  # when the port is already bound, so the supervisor retries instead of leaving
  # a live connection with no forwarding. On darwin this must be the system ssh:
  # the generated ssh_config uses UseKeychain, which upstream OpenSSH rejects.
  tunnelArgv = host: [
    (
      if pkgs.stdenv.isDarwin
      then "/usr/bin/ssh"
      else "${pkgs.openssh}/bin/ssh"
    )
    "-N"
    "-o"
    "ExitOnForwardFailure=yes"
    "-o"
    "ServerAliveInterval=30"
    "-o"
    "ServerAliveCountMax=3"
    "-R"
    "${toString cfg.source.remotePort}:127.0.0.1:${toString cfg.port}"
    host
  ];

  sinkPortList = lib.concatMapStringsSep " " toString cfg.sink.ports;

  # Finds the first source that actually answers with an image on its clipboard.
  #
  # Timeouts are short and deliberate. A source that went to sleep leaves its
  # forwarded listener bound on the sink (tailscaled owns the listener
  # in-process and does not release it when the peer stops answering), so
  # connections to a dead source are accepted and then hang forever rather than
  # being refused. Waiting the old 10s on the first such port made every paste
  # feel broken; 2s is well past a loopback round-trip and lets the loop move on
  # to a source that is awake.
  sinkProbe = ''
    curl_bridge() { # <port> <path> [curl args...]
      local port=$1 path=$2
      shift 2
      ${pkgs.curl}/bin/curl -sf --max-time 2 "$@" "http://127.0.0.1:$port$path"
    }

    # Echoes the port serving an image, or nothing when no source has one.
    image_port() {
      local port
      for port in ${sinkPortList}; do
        if curl_bridge "$port" /clipboard/type 2>/dev/null | grep -q '"image"'; then
          echo "$port"
          return 0
        fi
      done
      return 1
    }

    # Only ever called with a port that just answered the probe, so the transfer
    # gets a real budget: a large screenshot over a relayed tunnel is slow, but
    # it is no longer at risk of blocking on a dead source.
    fetch_image() { # <port> [curl args...]
      local port=$1
      shift
      ${pkgs.curl}/bin/curl -sf --max-time 20 "$@" "http://127.0.0.1:$port/clipboard/image"
    }
  '';

  # Shadows the real xclip. Claude Code calls it two ways: once to list
  # available targets, once to read the PNG itself.
  sinkXclip = pkgs.writeShellScriptBin "xclip" ''
    ${sinkProbe}
    case "$*" in
      *"-t TARGETS"*"-o"*)
        if image_port >/dev/null; then
          printf 'TARGETS\nimage/png\n'
        fi
        exit 0
        ;;
      *"-t image/png"*"-o"*)
        port=$(image_port) && fetch_image "$port" 2>/dev/null || true
        exit 0
        ;;
    esac
    # Headless host: no real xclip to delegate to, and text paste goes through
    # the terminal rather than the clipboard. Anything else is a no-op.
    exit 0
  '';

  sinkWlPaste = pkgs.writeShellScriptBin "wl-paste" ''
    ${sinkProbe}
    case "$*" in
      *"--list-types"*)
        if image_port >/dev/null; then
          printf 'image/png\ntext/plain\n'
        fi
        exit 0
        ;;
      *"--type image/"*|*"-t image/"*)
        port=$(image_port) && fetch_image "$port" 2>/dev/null || true
        exit 0
        ;;
    esac
    exit 0
  '';

  # For tools that read the clipboard in-process and never call xclip (Codex
  # CLI): materialise the image and print its path to hand over manually.
  sinkPasteHelper = pkgs.writeShellScriptBin "clipaste-paste" ''
    ${sinkProbe}
    if ! port=$(image_port); then
      echo "clipaste-paste: no image on the clipboard of the machine you SSH'd in from" >&2
      exit 1
    fi
    out="''${TMPDIR:-/tmp}/clipboard-bridge-$(date +%s)-$$.png"
    if fetch_image "$port" -o "$out" 2>/dev/null && [ -s "$out" ]; then
      echo "$out"
      exit 0
    fi
    rm -f "$out"
    echo "clipaste-paste: could not reach the clipboard bridge (is the tunnel up?)" >&2
    exit 1
  '';
  # Codex (and anything else built on the arboard crate) reads the clipboard
  # in-process over X11 rather than shelling out, so the shims above never see
  # it. Giving it a real headless X server whose CLIPBOARD selection we own makes
  # Ctrl+V work natively. X11 selections are pull-based, so the image is fetched
  # only when a paste actually happens — nothing polls.
  x11Owner = pkgs.writeScriptBin "clipboard-x11-owner" ''
    #!${pkgs.python3.withPackages (ps: [ps.xlib])}/bin/python3
    """Own the X CLIPBOARD selection, serving the remote image on demand."""
    import json
    import sys
    import urllib.request
    from Xlib import X, Xatom, display
    from Xlib.protocol import event

    PORTS = ${builtins.toJSON cfg.sink.ports}
    # Short, like the shell shims: a source that fell asleep leaves its listener
    # bound, so a connection to it is accepted and then never answered. Probing
    # cheaply first means a sleeping laptop costs 2s, not a hung paste.
    PROBE_TIMEOUT = 2
    FETCH_TIMEOUT = 20
    # One ChangeProperty cannot exceed the server's maximum request length, so
    # oversized images are appended in chunks. The requestor still sees a single
    # property, which avoids the INCR state machine entirely.
    CHUNK = 200000

    d = display.Display()
    win = d.screen().root.create_window(0, 0, 1, 1, 0, X.CopyFromParent)
    CLIPBOARD = d.get_atom("CLIPBOARD")
    TARGETS = d.get_atom("TARGETS")
    PNG = d.get_atom("image/png")


    def log(*a):
        """Journal every request: which target a client asked for is the only way
        to see why an in-process reader rejects what we offer."""
        print(*a, file=sys.stderr, flush=True)


    def fetch_image():
        """Return PNG bytes from the first source reporting an image, else b""."""
        for port in PORTS:
            base = "http://127.0.0.1:%d/clipboard" % port
            try:
                with urllib.request.urlopen(base + "/type", timeout=PROBE_TIMEOUT) as r:
                    if json.load(r).get("type") != "image":
                        continue
                with urllib.request.urlopen(base + "/image", timeout=FETCH_TIMEOUT) as r:
                    data = r.read()
            except Exception as exc:
                log("port", port, "-> unreachable:", exc)
                continue
            if data:
                return data
        return b""


    def serve(req):
        """Fill the requestor's property; return it, or NONE to refuse."""
        prop = req.property if req.property != X.NONE else req.target
        name = d.get_atom_name(req.target)
        try:
            if req.target == TARGETS:
                req.requestor.change_property(prop, Xatom.ATOM, 32, [TARGETS, PNG])
                log("request TARGETS -> offered image/png")
            elif req.target == PNG:
                data = fetch_image()
                if not data:
                    log("request", name, "-> refused: source returned no data")
                    return X.NONE
                req.requestor.change_property(prop, PNG, 8, data[:CHUNK])
                for i in range(CHUNK, len(data), CHUNK):
                    req.requestor.change_property(
                        prop, PNG, 8, data[i:i + CHUNK], mode=X.PropModeAppend
                    )
                log("request", name, "-> served", len(data), "bytes")
            else:
                log("request", name, "-> refused: unsupported target")
                return X.NONE
        except Exception as exc:
            # A dead tunnel must not kill the owner, or paste breaks until restart.
            log("request", name, "-> failed:", exc)
            return X.NONE
        return prop


    win.set_selection_owner(CLIPBOARD, X.CurrentTime)
    d.sync()
    while True:
        e = d.next_event()
        if e.type == X.SelectionRequest:
            d.send_event(e.requestor, event.SelectionNotify(
                time=e.time, requestor=e.requestor, selection=e.selection,
                target=e.target, property=serve(e)))
            d.flush()
        elif e.type == X.SelectionClear:
            win.set_selection_owner(CLIPBOARD, X.CurrentTime)
            d.sync()
  '';
in {
  options.services.clipboardBridge = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 18340;
      description = ''
        Loopback port the source daemon listens on, on the source machine
        itself. 18340 is upstream clipaste's default, so this stays compatible
        with the real clipaste daemon on hosts that run it.

        This is the local end of the tunnel only. Which port the forward binds
        on the sink is `source.remotePort`, and which ports the sink reads from
        is `sink.ports`.
      '';
    };

    source = {
      enable = lib.mkEnableOption "the clipboard bridge daemon (machines with a real clipboard)";

      tunnelTo = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = lib.literalExpression ''["home-server"]'';
        description = ''
          SSH host aliases to keep a reverse tunnel open to, so the sink can
          reach this machine's clipboard.

          Putting RemoteForward in ssh_config instead ties the tunnel to
          interactive sessions, and only the first one can bind the port: every
          later session warns and silently continues without a tunnel, so paste
          works or not depending on which session happens to be oldest. A
          dedicated connection owns the port instead, and paste keeps working
          with any number of sessions, or none.
        '';
      };

      remotePort = lib.mkOption {
        type = lib.types.port;
        default = cfg.port;
        description = ''
          Port this machine's reverse tunnel binds on the sink. Every source
          that tunnels to the same sink needs a distinct one: only the first
          can bind, and the losers' tunnel units then crash-loop forever on
          `remote port forwarding failed`, with no paste from those machines.

          The failure outlives the session that caused it when the sink is
          reached over Tailscale SSH. There the listener belongs to tailscaled
          itself rather than to a per-session sshd child, so a source that
          sleeps mid-session leaves the port bound and unanswering until
          tailscaled restarts.
        '';
      };

      backend = lib.mkOption {
        type = lib.types.enum ["macos" "wayland" "x11"];
        default =
          if pkgs.stdenv.isDarwin
          then "macos"
          else "wayland";
        description = "Which clipboard implementation to read from.";
      };
    };

    sink = {
      enable = lib.mkEnableOption "the xclip/wl-paste shims (headless hosts running Claude Code)";

      ports = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [cfg.port];
        example = lib.literalExpression "[18340 18341]";
        description = ''
          Ports to look for a source on, in order — one per source machine's
          `source.remotePort`. The first that reports an image on its clipboard
          wins, so paste serves whichever machine you are actually typing on
          rather than whichever one happened to connect first.

          Order matters only as a tie-break when two sources both hold an
          image; put the machine you SSH in from most often first.
        '';
      };

      x11 = {
        enable = lib.mkEnableOption ''
          a headless X server owning the CLIPBOARD selection, so in-process
          clipboard readers (Codex, and anything else using arboard) can paste
          natively instead of going through the xclip shim
        '';

        display = lib.mkOption {
          type = lib.types.str;
          default = ":99";
          description = "Display the headless X server runs on.";
        };

        wrapPrograms = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          example = lib.literalExpression "[ inputs.llm-agents.packages.\${system}.codex ]";
          description = ''
            Packages whose executables read the clipboard in-process over X11
            and therefore need DISPLAY pointing at the headless server. Each is
            re-exposed with DISPLAY set and takes precedence over the unwrapped
            package, so DISPLAY does not have to be set for the whole session.
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.source.tunnelTo != []) (lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents =
          lib.listToAttrs (map (host:
            lib.nameValuePair "clipboard-tunnel-${host}" {
              enable = true;
              config = {
                ProgramArguments = tunnelArgv host;
                RunAtLoad = true;
                KeepAlive = true;
              };
            })
          cfg.source.tunnelTo);
      })

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services =
          lib.listToAttrs (map (host:
            lib.nameValuePair "clipboard-tunnel-${host}" {
              Unit = {
                Description = "Reverse clipboard tunnel to ${host}";
                After = ["network-online.target"];
              };
              Service = {
                ExecStart = lib.escapeShellArgs (tunnelArgv host);
                Restart = "always";
                RestartSec = "5";
              };
              Install.WantedBy = ["default.target"];
            })
          cfg.source.tunnelTo);
      })
    ]))

    (lib.mkIf cfg.source.enable (lib.mkMerge [
      {home.packages = [sourceDaemon];}

      # mkIf, not optionalAttrs: deciding the *shape* of config from `pkgs`
      # forces `config` to resolve `_module.args`, which is infinite recursion.
      # home-manager imports both launchd and systemd unconditionally, so both
      # option paths exist on either platform and only the condition differs.
      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.clipboard-bridge = {
          enable = true;
          config = {
            ProgramArguments = ["${sourceDaemon}/bin/clipboard-bridge"];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/clipboard-bridge.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/clipboard-bridge.log";
          };
        };
      })

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.clipboard-bridge = {
          Unit = {
            Description = "Clipboard bridge (serves clipboard images to remote SSH sessions)";
            # Needs the compositor's environment (WAYLAND_DISPLAY) to read the
            # clipboard, so it lives and dies with the graphical session.
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "simple";
            ExecStart = "${sourceDaemon}/bin/clipboard-bridge";
            Restart = "on-failure";
            RestartSec = "5";
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      })
    ]))

    (lib.mkIf cfg.sink.enable {
      home.packages = [sinkXclip sinkWlPaste sinkPasteHelper];
    })

    (lib.mkIf (cfg.sink.enable && cfg.sink.x11.enable) {
      # Deliberately no global DISPLAY. On a headless host that would advertise a
      # display to every tool on the box, most of which would then behave as if a
      # GUI existed. Only the programs that actually read the clipboard in-process
      # need it, so they are wrapped individually via wrapPrograms below.

      # hiPrio so these win the collision against the unwrapped package, which
      # stays in home.packages via the shared package list.
      home.packages = map (p:
        lib.hiPrio (pkgs.symlinkJoin {
          name = "${lib.getName p}-x11";
          paths = [p];
          nativeBuildInputs = [pkgs.makeWrapper];
          postBuild = lib.concatMapStrings (bin: ''
            wrapProgram $out/bin/${bin} --set DISPLAY ${cfg.sink.x11.display}
          '') (builtins.attrNames (builtins.readDir "${p}/bin"));
        }))
      cfg.sink.x11.wrapPrograms;

      systemd.user.services.clipboard-xvfb = {
        Unit.Description = "Headless X server backing remote clipboard paste";
        Service = {
          # /tmp/.X11-unix does not exist on a headless host; /tmp is sticky, so
          # creating it needs no privileges.
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /tmp/.X11-unix";
          ExecStart = "${pkgs.xorg.xvfb}/bin/Xvfb ${cfg.sink.x11.display} -screen 0 16x16x8 -nolisten tcp";
          Restart = "on-failure";
          RestartSec = "2";
        };
        Install.WantedBy = ["default.target"];
      };

      systemd.user.services.clipboard-x11-owner = {
        Unit = {
          Description = "Owns the X CLIPBOARD selection, serving images on demand";
          After = ["clipboard-xvfb.service"];
          Requires = ["clipboard-xvfb.service"];
        };
        Service = {
          Environment = "DISPLAY=${cfg.sink.x11.display}";
          ExecStart = "${x11Owner}/bin/clipboard-x11-owner";
          Restart = "on-failure";
          RestartSec = "2";
        };
        Install.WantedBy = ["default.target"];
      };
    })
  ];
}
