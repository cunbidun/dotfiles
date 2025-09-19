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

      waybar = {
        Service = {
          RestartSec = 1;
        };
      };

      hyprpanel = {
        Service = {
          # Restart within 2 seconds
          RestartSec = 1;
          # Force SIGKILL after 2 seconds if graceful stop fails
          TimeoutStopSec = 1;
        };
      };
    };
  };
}
