{
  config,
  pkgs,
  lib,
  project_root,
  userdata,
  inputs,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
in {
  programs.ags = {
    enable = true;
    extraPackages = with inputs.ags.packages.${pkgs.system}; [
      hyprland
    ];
  };

  # AGS configuration files with hot reload support
  home.file = {
    ".config/ags" = {
      source =
        if userdata.hermeticAgsConfig
        then "${project_root}/nix/home-manager/configs/hyprland/ags"
        else config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nix/home-manager/configs/hyprland/ags";
      recursive = true;
    };
  };

  # Systemd services for AGS
  systemd.user.services = {
    ags = {
      Unit = {
        Description = "AGS (Astal GTK Shell)";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${inputs.ags.packages.${pkgs.system}.default}/bin/ags run ${config.home.homeDirectory}/.config/ags/app.js";
        Restart = "on-failure";
        RestartSec = "1";
        Environment = "PATH=${lib.makeBinPath [pkgs.bash pkgs.coreutils]}";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    ags-reload = {
      Unit = {
        Description = "Reload AGS on config change";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart ags.service";
      };
    };
  };

  systemd.user.paths = {
    ags-config-watcher = {
      Unit = {
        Description = "Watch AGS config directory for changes";
      };
      Path = {
        PathModified = "${config.home.homeDirectory}/.config/ags";
        Unit = "ags-reload.service";
      };
      Install = {
        WantedBy = ["ags.service"];
      };
    };
  };

  # Ensure AGS can access necessary system tools
  home.packages = with pkgs; [
    brightnessctl
    pulsemixer
    bluetuith
    networkmanager
    wireplumber
  ];
}
