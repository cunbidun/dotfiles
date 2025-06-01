{
  inputs,
  pkgs,
  lib,
  project_root,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
  unit_section = {
    After = ["graphical-session.target"];
  };
  install_section = {
    WantedBy = ["graphical-session.target"];
  };
in {
  systemd.user = {
    services = {
      pypr = {
        Unit = unit_section;
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe' inputs.pyprland.packages.${pkgs.system}.pyprland "pypr"}";
          StandardOutput = "journal";
          StandardError = "journal";
          ExecStopPost = "/bin/sh -c 'rm -f \${XDG_RUNTIME_DIR}/hypr/\${HYPRLAND_INSTANCE_SIGNATURE}/.pyprland.sock'";
          Slice = ["app-graphical.slice"];
        };
        Install = install_section;
      };

      hyprland_autostart = {
        Unit = unit_section;
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${scripts.hyprland-autostart}/bin/hyprland-autostart";
          StandardOutput = "journal";
          StandardError = "journal";
          Slice = ["app-graphical.slice"];
        };
        Install = install_section;
      };

      sync_weather = {
        Unit = unit_section;
        Service = {
          Type = "oneshot";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe scripts.weather-sync}";
          Slice = ["app-graphical.slice"];
        };
        Install = install_section;
      };

      waybar = {
        Service = {
          RestartSec = 1;
        };
      };
    };

    timers = {
      sync_weather = {
        Unit = unit_section;
        Timer = {OnCalendar = "*:0/10";};
        Install = install_section;
      };
    };
  };
}
