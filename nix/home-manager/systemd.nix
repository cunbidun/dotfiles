{pkg, ...}: {
  services = {
    waybar = {
      Unit = {
        Description = "Waybar Service";
        After = "network.target";
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.waybar}";
        StandardOutput = "journal";
        StandardError = "journal";
        Restart = "always";
        RestartSec = 10;
        Environment =
          let
            path = lib.makeBinPath [ pkgs.waybar];
          in
          [ "PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin" ];
      };
    };
    waybar_config_watcher = {
      Unit = {
        Description = "Waybar Restarter Service";
        After = "network.target";
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart waybar.service";
      };
    };
  };
  paths = {
    waybar_config_watcher = {
      Path = {
        PathModified="%h/dotfiles/window_manager/hyprland/linux/.config/waybar/";
      };
    };
  };
}
