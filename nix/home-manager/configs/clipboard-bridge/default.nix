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
# Transport is an SSH reverse tunnel onto a unix socket rather than a TCP port:
# a forwarded TCP port on the sink is reachable by every local account there
# (home-server has an unprivileged tailnet-guest user), whereas sshd creates
# forwarded sockets 0600-owned by the connecting user.
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
    PORT = ${toString cfg.source.port}


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

  # Talks to the source daemon through the forwarded socket. `curl` needs a URL
  # even when the transport is a unix socket, hence the placeholder host.
  curlSocket = "${pkgs.curl}/bin/curl -sf --unix-socket ${cfg.socketPath}";

  # Shadows the real xclip. Claude Code calls it two ways: once to list
  # available targets, once to read the PNG itself.
  sinkXclip = pkgs.writeShellScriptBin "xclip" ''
    case "$*" in
      *"-t TARGETS"*"-o"*)
        if ${curlSocket} http://localhost/clipboard/type 2>/dev/null | grep -q '"image"'; then
          printf 'TARGETS\nimage/png\n'
        fi
        exit 0
        ;;
      *"-t image/png"*"-o"*)
        ${curlSocket} http://localhost/clipboard/image 2>/dev/null || true
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
        if ${curlSocket} http://localhost/clipboard/type 2>/dev/null | grep -q '"image"'; then
          printf 'image/png\ntext/plain\n'
        fi
        exit 0
        ;;
      *"--type image/"*|*"-t image/"*)
        ${curlSocket} http://localhost/clipboard/image 2>/dev/null || true
        exit 0
        ;;
    esac
    exit 0
  '';

  # For tools that read the clipboard in-process and never call xclip (Codex
  # CLI): materialise the image and print its path to hand over manually.
  sinkPasteHelper = pkgs.writeShellScriptBin "clipaste-paste" ''
    if ! ${curlSocket} http://localhost/clipboard/type 2>/dev/null | grep -q '"image"'; then
      echo "clipaste-paste: no image on the clipboard of the machine you SSH'd in from" >&2
      exit 1
    fi
    out="''${TMPDIR:-/tmp}/clipboard-bridge-$(date +%s)-$$.png"
    if ${curlSocket} -o "$out" http://localhost/clipboard/image 2>/dev/null && [ -s "$out" ]; then
      echo "$out"
      exit 0
    fi
    rm -f "$out"
    echo "clipaste-paste: could not reach the clipboard bridge (is the tunnel up?)" >&2
    exit 1
  '';
in {
  options.services.clipboardBridge = {
    socketPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000/clipboard-bridge.sock";
      description = ''
        Unix socket on the sink host that the SSH reverse tunnel binds. Sources
        point their RemoteForward at this path; the sink's shims read from it.
        Must be writable by the SSH user on the sink (uid 1000 there).
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

      port = lib.mkOption {
        type = lib.types.port;
        default = 18340;
        description = "Loopback port the daemon listens on (clipaste's default).";
      };
    };

    sink = {
      enable = lib.mkEnableOption "the xclip/wl-paste shims (headless hosts running Claude Code)";
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
  ];
}
