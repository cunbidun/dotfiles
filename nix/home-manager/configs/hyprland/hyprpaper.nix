{pkgs, ...}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
    };
  };

  # One-shot service to restart hyprpaper
  systemd.user.services.hyprpaper-restart = {
    Unit = {
      Description = "Restart hyprpaper service";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
    };
  };

  # Path watcher to restart hyprpaper when config changes
  systemd.user.paths.hyprpaper-config-watcher = {
    Unit = {
      Description = "Watch hyprpaper config file for changes";
    };
    Path = {
      # Watch both the file and the directory to catch file recreations
      PathModified = "%h/.config/hypr/hyprpaper.conf";
      PathChanged = "%h/.config/hypr";
      Unit = "hyprpaper-restart.service";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
