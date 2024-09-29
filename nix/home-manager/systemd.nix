{
  inputs,
  pkgs,
  lib,
  project_root,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
in {
  systemd.user = {
    services = {
      # +--------+
      # | waybar |
      # +--------+
      waybar = {
        Unit = {
          Description = "Waybar Service";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe pkgs.waybar}";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      # +-----+
      # | ags |
      # +-----+
      ags = {
        Unit = {
          Description = "Ags Service";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe pkgs.ags}";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      pypr = {
        Unit = {
          Description = "Pypr Service";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe' inputs.pyprland.packages.${pkgs.system}.pyprland "pypr"}";
          StandardOutput = "journal";
          StandardError = "journal";
          ExecStopPost = "/bin/sh -c 'rm -f \${XDG_RUNTIME_DIR}/hypr/\${HYPRLAND_INSTANCE_SIGNATURE}/.pyprland.sock'";
        };
      };

      activitywatch = {
        Unit = {
          Description = "Activit Watch service";
          After = ["waybar.service"];
          Requires = ["waybar.service"];
        };
        Service = {
          ExecStartPre = "/bin/sh -c 'sleep 3'";
          Type = "simple";
          ExecStart = "/bin/sh -c 'aw-qt'";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      syncthing = {
        Unit = {
          Description = "Syncthing Service";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe pkgs.syncthing}";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      hyprland_autostart = {
        Unit = {
          Description = "Hyprland Auto Start Script";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${scripts.hyprland-autostart}/bin/hyprland-autostart";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };

      waybar_config_watcher = {
        Unit = {Description = "Waybar Restarter Service";};
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h";
          ExecStart = "systemctl --user restart waybar.service";
        };
      };

      ags_config_watcher = {
        Unit = {Description = "Ags Restarter Service";};
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h";
          ExecStart = "systemctl --user restart ags.service";
        };
      };

      sync_weather = {
        Unit = {
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe scripts.weather-sync}";
        };
      };

      hyprland = {
        Unit = {
          Description = "My hyprland wrapper that runs it in systemd";
          Before = ["graphical-session.target"]; # make sure hyprland ready before graphical-session.target
          After = ["graphical-session-pre.target"];
          Wants = [
            "activitywatch.service"
            "ags.service"
            "ags_config_watcher.path"
            "gammastep.service"
            "hypridle.service"
            "hyprland_autostart.service"
            "hyprpaper.service"
            "pypr.service"
            "sync_weather.service"
            "sync_weather.timer"
            "syncthing.service"
            "waybar.service"
            "waybar_config_watcher.path"
            "fcitx5-daemon.service"

            "graphical-session-pre.target"
          ];
        };
        Service = {
          Type = "notify";
          ExecStartPre = "systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe inputs.hyprland.packages.${pkgs.system}.hyprland}";
          StandardOutput = "journal";
          StandardError = "journal";
          TimeoutStopSec = 5;
        };
      };
    };
    paths = {
      waybar_config_watcher = {
        Unit = {
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Path = {
          PathModified = "%h/.config/waybar/";
        };
      };
      ags_config_watcher = {
        Unit = {
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Path = {PathModified = "%h/.config/ags/";};
      };
    };
    timers = {
      sync_weather = {
        Unit = {
          Description = "Sync weather timer";
          After = ["hyprland.service"];
          Requires = ["hyprland.service"];
        };
        Timer = {OnCalendar = "*:0/10";};
      };
    };
  };
}
