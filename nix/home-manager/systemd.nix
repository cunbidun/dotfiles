{ inputs, pkgs, lib, project_root, ... }: {
  services = {
    waybar = {
      Unit = {
        Description = "Waybar Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${
            lib.getExe pkgs.waybar
          } --config %h/dotfiles/window_manager/hyprland/linux/.config/waybar/config --style %h/dotfiles/window_manager/hyprland/linux/.config/waybar/style.css";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    ags = {
      Unit = {
        Description = "Ags Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart =
          "${lib.getExe pkgs.ags} --config %h/dotfiles/utilities/ags/config.js";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    pypr = {
      Unit = {
        Description = "Pypr Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.pyprland}";
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStopPost =
          "/bin/sh -c 'rm -f /tmp/hypr/\${HYPRLAND_INSTANCE_SIGNATURE}/.pyprland.sock'";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    hyprpaper = {
      Unit = {
        Description = "hyprpaper Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.hyprpaper}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    gammastep = {
      Unit = {
        Description = "Gamma Step Service";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        WorkingDirectory = "%h";
        ExecStart = "${lib.getExe pkgs.gammastep} -l 41.85003:-87.65005";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
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
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    hyprland_autostart = {
      Unit = {
        Description = "Hyprland Auto Start Script";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        ExecStartPre = "/bin/sh -c 'sleep 1'";
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart =
          "${project_root}/window_manager/hyprland/scripts/autostart.sh";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    waybar_config_watcher = {
      Unit = { Description = "Waybar Restarter Service"; };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart waybar.service";
      };
    };
    ags_config_watcher = {
      Unit = { Description = "Ags Restarter Service"; };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart ags.service";
      };
    };
    sync_weather = {
      Unit = {
        Description = "Sync weather";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "${project_root}/local/linux/.local/bin/sc_weather_sync";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    hyprpaper_config_watcher = {
      Unit = { Description = "Hyprpaper Config Watcher"; };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        ExecStart = "systemctl --user restart hyprpaper.service";
      };
    };
    hyprland = {
      Unit = { Description = "My hyprland wrapper that runs it in systemd"; };
      Service = {
        Type = "simple";
        ExecStartPre =
          "systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY";
        WorkingDirectory = "%h";
        ExecStart =
          "${lib.getExe inputs.hyprland.packages.${pkgs.system}.hyprland}";
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
        PathModified =
          "%h/dotfiles/window_manager/hyprland/linux/.config/waybar/";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    hyprpaper_config_watcher = {
      Unit = {
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Path = {
        PathModified =
          "%h/dotfiles/window_manager/hyprland/linux/.config/hypr/hyprpaper.conf";
      };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
    ags_config_watcher = {
      Unit = {
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Path = { PathModified = "%h/dotfiles/utilities/ags"; };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
  };
  timers = {
    sync_weather = {
      Unit = {
        Description = "Sync weather timer";
        PartOf = [ "hyprland.service" ];
        After = [ "hyprland.service" ];
        Requires = [ "hyprland.service" ];
      };
      Timer = { OnCalendar = "*:0/30"; };
      Install = { WantedBy = [ "hyprland.service" ]; };
    };
  };
}
