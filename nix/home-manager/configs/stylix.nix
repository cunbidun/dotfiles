{
  inputs,
  pkgs,
  lib,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
in {
  services.darkman = {
    enable =
      if isLinux
      then true
      else false;

    darkModeScripts = {
      dark-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch dark
      '';
    };
    lightModeScripts = {
      light-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch light
      '';
    };

    settings = {
      usegeoclue = true;
    };
  };
  specialisation.light-theme.configuration = {
    # Helper                  | Priority it sets  | Typical use
    # lib.mkDefault value     | 1000              | Ship a safe default that users can override easily
    # lib.mkOverride N value  | N (you pick)      | Fine‑tune how strongly you want to win/lose merges
    # lib.mkForce value       | 50                | “Last word”—almost always beats everything else

    # force light mode with lowest number (highest priority)
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkOverride 1 "prefer-light";

    stylix = {
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/standardized-light.yaml";
      image = lib.mkForce ../../../wallpapers/thuonglam.jpeg;
    };
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-dark";
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/standardized-dark.yaml";
    image = ../../../wallpapers/Astronaut.png;

    targets = {
      waybar.enable = false;
      vscode.enable = false;
      gnome.enable = true;
      kde.enable = true;
      gtk.enable = true;
      yazi.enable = true;
    };

    # https://github.com/phisch/phinger-cursors
    cursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 24;
    };

    opacity = {
      terminal = 0.85;
    };

    fonts = {
      sizes = {
        applications = 11;
        terminal = 10;
        desktop = 10;
      };
      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.ny-nerd;
        name = "NewYork Nerd Font";
      };

      sansSerif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };

      monospace = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
        name = "SFMono Nerd Font";
      };
    };
  };
}
