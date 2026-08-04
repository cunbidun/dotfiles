# ActivityWatch watcher role -- a desktop that produces activity but stores none
# of it. The server lives on home-server (see ./server.nix).
{pkgs, ...}: let
  endpoint = import ./endpoint.nix;
  awatcher = pkgs.nixpkgs-stable.awatcher;
in {
  imports = [./tmux-watcher.nix];

  # home-manager's services.activitywatch module always pairs watchers with a
  # local aw-server and offers no way to drop it, which is precisely what this
  # host no longer wants -- so the one watcher is declared directly instead.
  systemd.user.services.activitywatch-watcher-awatcher = {
    Unit = {
      Description = "ActivityWatch watcher 'awatcher'";
      # awatcher reads the compositor's window and idle state, so it needs the
      # graphical session's environment and is pointless without it.
      After = ["graphical-session.target"];
      Requisite = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${awatcher}/bin/awatcher --host ${endpoint.host} --port ${toString endpoint.port}";
      # home-server may be unreachable at login (tailnet still coming up), and
      # awatcher exits rather than retrying, so restart until it sticks.
      Restart = "on-failure";
      RestartSec = "10";
      LockPersonality = true;
      NoNewPrivileges = true;
      RestrictNamespaces = true;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Everything that assumes ActivityWatch is on localhost -- the web UI, the
  # Chrome extension, the VS Code extension -- keeps working, forwarded to
  # home-server. Those clients hardcode 127.0.0.1:5600 with no setting to change
  # (the browser extension's server URL lives in extension storage, which nix
  # cannot reach), so without this they silently post into a closed port.
  #
  # A raw TCP forward specifically, not an HTTP proxy: the client's own Host and
  # Origin headers pass through untouched as localhost:5600, which is exactly
  # what aw-server-rust's cross-origin guard admits without configuration.
  systemd.user.sockets.activitywatch-proxy = {
    Unit.Description = "Local ActivityWatch port, forwarded to ${endpoint.host}";
    Socket.ListenStream = "127.0.0.1:${toString endpoint.port}";
    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.activitywatch-proxy = {
    Unit = {
      Description = "Forward local ActivityWatch traffic to ${endpoint.host}";
      Requires = ["activitywatch-proxy.socket"];
      After = ["activitywatch-proxy.socket"];
    };
    Service = {
      # Socket-activated: no Install section, the socket unit starts this.
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${endpoint.host}:${toString endpoint.port}";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };
}
