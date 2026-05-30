{pkgs, ...}: {
  services.activitywatch = {
    enable = true;
    package = pkgs.nixpkgs-stable.aw-server-rust;
    watchers = {awatcher.package = pkgs.nixpkgs-stable.awatcher;};
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
