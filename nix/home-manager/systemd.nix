{pkgs, lib, ...}: {
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
    sc_hyprland_count_minimized = {
      Unit = {
        Description = "Hyprland Minimize Daemon";
        After = "network.target";
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "%h/dotfiles/local/linux/.local/bin/sc_hyprland_count_minimized.py";
        StandardOutput = "journal";
        StandardError = "journal";
        Restart = "always";
        RestartSec = 10;
        Environment = [ 
          "PYTHONUNBUFFERED=1" 
          "HOME=%h" 
        ];
      };
    };
    sc_hyprland_count_minimized_watcher = {
      Unit = {
        Description = "Hyprland Minimize Daemon Restarter";
        After = "network.target";
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart sc_hyprland_count_minimized.service";
      };
    };

  };
  paths = {
    waybar_config_watcher = {
      Path = {
        PathModified="%h/dotfiles/window_manager/hyprland/linux/.config/waybar/";
      };
    };
    sc_hyprland_count_minimized_watcher = {
      Path = {
        PathModified="%h/dotfiles/local/linux/.local/bin/sc_hyprland_count_minimized.py";
      };
    };
  };
}
