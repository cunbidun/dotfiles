{pkgs, lib, project_root, ...}: {
  services = {
    waybar = {
      Unit = {
        Description = "Waybar Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre="/bin/sleep 1";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.waybar}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    pypr = {
      Unit = {
        Description = "Pypr Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.pyprland}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    xremap = {
      Unit = {
        Description = "Xremap Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "/usr/bin/xremap /home/cunbidun/.config/xremap/config.yml";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    syncthing = {
      Unit = {
        Description = "Syncthing Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.syncthing}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    hyprland_autostart = {
      Unit = {
        Description = "Hyprland Auto Start Script";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${project_root}/window_manager/hyprland/scripts/autostart.sh";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    waybar_config_watcher = {
      Unit = {
        Description = "Waybar Restarter Service";
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
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${project_root}/local/linux/.local/bin/sc_hyprland_count_minimized.py";
        StandardOutput = "journal";
        StandardError = "journal";
        Environment = [ 
          "PYTHONUNBUFFERED=1" 
        ];
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    sc_hyprland_count_minimized_watcher = {
      Unit = {
        Description = "Hyprland Minimize Daemon Restarter";
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart sc_hyprland_count_minimized.service";
      };
    };
    hyprland = {
      Unit = {
        Description = "My hyprland wrapper that runs it in systemd";
      };
      Service = {
        Type = "notify";
        ExecStartPre = "systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY";
        WorkingDirectory = "%h";
        ExecStart = "/usr/bin/Hyprland";
        StandardOutput = "journal";
        StandardError = "journal";
        TimeoutStopSec = 5;
      };
    };
  };
  paths = {
    waybar_config_watcher = {
      Unit = {
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Path = {
        PathModified="%h/dotfiles/window_manager/hyprland/linux/.config/waybar/";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
    sc_hyprland_count_minimized_watcher = {
      Unit = {
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Path = {
        PathModified="%h/dotfiles/local/linux/.local/bin/sc_hyprland_count_minimized.py";
      };
      Install = {
        WantedBy = [ "hyprland.service" ];
      };
    };
  };
}
