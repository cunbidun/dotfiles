{
  inputs,
  pkgs,
  lib,
  ...
}: let
  scripts = import ./scripts.nix {pkgs = pkgs;};
  unit_section = {
    After = ["graphical-session.target"];
  };
  install_section = {
    WantedBy = ["graphical-session.target"];
  };
in {
  systemd.user = {
    services = {
      nix-gc = {
        Unit.Description = "Nix garbage collection for home-manager generations";
        Service = {
          Type = "oneshot";
          ExecStart = "/bin/sh -c '${pkgs.nix}/bin/nix-env -p %h/.local/state/nix/profiles/home-manager --delete-generations 30d && ${pkgs.nix}/bin/nix-collect-garbage'";
        };
      };

      pypr = {
        Unit = unit_section;
        Service = {
          Type = "simple";
          WorkingDirectory = "%h";
          ExecStart = "${lib.getExe' inputs.pyprland.packages.${pkgs.stdenv.hostPlatform.system}.pyprland "pypr"}";
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
    };

    timers = {
      nix-gc = {
        Unit.Description = "Weekly Nix garbage collection for home-manager generations";
        Timer = {
          OnCalendar = "weekly";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
