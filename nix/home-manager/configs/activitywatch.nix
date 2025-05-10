{pkgs, ...}: {
  services.activitywatch = {
    enable = true;
    package = pkgs.aw-server-rust;
    watchers = {awatcher.package = pkgs.awatcher;};
  };

  # awatcher should start and stop depending on wayland-session.target
  # starting activitywatch should only start awatcher if wayland-session.target is active
  systemd.user.services = {
    activitywatch-watcher-awatcher = {
      Unit = {
        After = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
