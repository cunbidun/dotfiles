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

  # Talks to the source daemon through the forwarded loopback port.
  curlBase = "${pkgs.curl}/bin/curl -sf --max-time 10 http://127.0.0.1:${toString cfg.port}";

  # Shadows the real xclip. Claude Code calls it two ways: once to list
  # available targets, once to read the PNG itself.
  sinkXclip = pkgs.writeShellScriptBin "xclip" ''
    case "$*" in
      *"-t TARGETS"*"-o"*)
        if ${curlBase}/clipboard/type 2>/dev/null | grep -q '"image"'; then
          printf 'TARGETS\nimage/png\n'
        fi
        exit 0
        ;;
      *"-t image/png"*"-o"*)
        ${curlBase}/clipboard/image 2>/dev/null || true
        exit 0
        ;;
    esac
    # Headless host: no real xclip to delegate to, and text paste goes through
    # the terminal rather than the clipboard. Anything else is a no-op.
    exit 0
  '';

  sinkWlPaste = pkgs.writeShellScriptBin "wl-paste" ''
    case "$*" in
      *"--list-types"*)
        if ${curlBase}/clipboard/type 2>/dev/null | grep -q '"image"'; then
          printf 'image/png\ntext/plain\n'
        fi
        exit 0
        ;;
      *"--type image/"*|*"-t image/"*)
        ${curlBase}/clipboard/image 2>/dev/null || true
        exit 0
        ;;
    esac
    exit 0
  '';

  # For tools that read the clipboard in-process and never call xclip (Codex
  # CLI): materialise the image and print its path to hand over manually.
  sinkPasteHelper = pkgs.writeShellScriptBin "clipaste-paste" ''
    if ! ${curlBase}/clipboard/type 2>/dev/null | grep -q '"image"'; then
      echo "clipaste-paste: no image on the clipboard of the machine you SSH'd in from" >&2
      exit 1
    fi
    out="''${TMPDIR:-/tmp}/clipboard-bridge-$(date +%s)-$$.png"
    if ${curlBase}/clipboard/image -o "$out" 2>/dev/null && [ -s "$out" ]; then
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
    import urllib.request
    from Xlib import X, Xatom, display
    from Xlib.protocol import event

    URL = "http://127.0.0.1:${toString cfg.port}/clipboard/image"
    # One ChangeProperty cannot exceed the server's maximum request length, so
    # oversized images are appended in chunks. The requestor still sees a single
    # property, which avoids the INCR state machine entirely.
    CHUNK = 200000

    d = display.Display()
    win = d.screen().root.create_window(0, 0, 1, 1, 0, X.CopyFromParent)
    CLIPBOARD = d.get_atom("CLIPBOARD")
    TARGETS = d.get_atom("TARGETS")
    PNG = d.get_atom("image/png")


    def serve(req):
        """Fill the requestor's property; return it, or NONE to refuse."""
        prop = req.property if req.property != X.NONE else req.target
        try:
            if req.target == TARGETS:
                req.requestor.change_property(prop, Xatom.ATOM, 32, [TARGETS, PNG])
            elif req.target == PNG:
                with urllib.request.urlopen(URL, timeout=10) as r:
                    data = r.read()
                if not data:
                    return X.NONE
                req.requestor.change_property(prop, PNG, 8, data[:CHUNK])
                for i in range(CHUNK, len(data), CHUNK):
                    req.requestor.change_property(
                        prop, PNG, 8, data[i:i + CHUNK], mode=X.PropModeAppend
                    )
            else:
                return X.NONE
        except Exception:
            # A dead tunnel must not kill the owner, or paste breaks until restart.
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
        Loopback port the source daemon listens on and that the SSH reverse
        tunnel binds on the sink. Sources point their RemoteForward at it; the
        sink's shims read from it. 18340 is upstream clipaste's default, so the
        shims stay compatible with the real clipaste daemon.
      '';
    };

    source = {
      enable = lib.mkEnableOption "the clipboard bridge daemon (machines with a real clipboard)";

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
      };
    };
  };

  config = lib.mkMerge [
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
      # Point every session at the headless server, so clipboard readers find it.
      home.sessionVariables.DISPLAY = cfg.sink.x11.display;

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
