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
}
