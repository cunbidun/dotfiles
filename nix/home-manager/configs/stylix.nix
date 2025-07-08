{
  config,
  inputs,
  pkgs,
  lib,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
in {
  services.darkman = {
    enable = isLinux;

    darkModeScripts = {
      dark-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch -p dark
      '';
    };
    lightModeScripts = {
      light-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch -p light
      '';
    };

    settings = {
      usegeoclue = true;
    };
  };

  services.theme-manager = {
    enable = true;
    themes = ["default" "nord"];
    hookScriptContent = ''
      #!/usr/bin/env bash
      /etc/profiles/per-user/${userdata.username}/bin/theme-switch
    '';
  };

  # NOTE:
  # to get the theme name: https://github.com/tinted-theming/schemes

  # NOTE:
  # the specialisation name for theme must be named '{theme}-{polarity}'. Else switch won't work
  # By default, the default configuration is 'default-dark' (with 'default-light')

  # NOTE on priority
  # Helper                  | Priority it sets  | Typical use
  # lib.mkDefault value     | 1000              | Ship a safe default that users can override easily
  # lib.mkOverride N value  | N (you pick)      | Fine‑tune how strongly you want to win/lose merges
  # lib.mkForce value       | 50                | “Last word”—almost always beats everything else

  # nord
  specialisation.nord-light.configuration = {
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkOverride 1 "prefer-light";
    stylix = {
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/nord-light.yaml";
      image = lib.mkForce ../../../wallpapers/thuonglam.jpeg;
    };
    home.activation.reconciliation_theme = lib.mkForce ''
      #!/usr/bin/env bash
      # no-op script to avoid double activation
    '';
  };

  specialisation.nord-dark.configuration = {
    stylix = {
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/nord.yaml";
      image = ../../../wallpapers/Astronaut.png;
    };
    home.activation.reconciliation_theme = lib.mkForce ''
      #!/usr/bin/env bash
      # no-op script to avoid double activation
    '';
  };

  # default
  specialisation.default-light.configuration = {
    # force light mode with lowest number (highest priority)
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkOverride 1 "prefer-light";
    stylix = {
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/standardized-light.yaml";
      image = lib.mkForce ../../../wallpapers/thuonglam.jpeg;
    };
    home.activation.reconciliation_theme = lib.mkForce ''
      #!/usr/bin/env bash
      # no-op script to avoid double activation
    '';
  };

  home.activation = {
    reconciliation_theme = lib.mkIf isLinux ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Running theme reconciliation..."
      POLARITY="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo dark)"   # dark by default
      THEME="$(${inputs.theme-manager.packages.${pkgs.system}.theme-manager}/bin/themectl get-theme 2>/dev/null || echo default)"  # dark by default
      echo "Detected theme: $THEME, polarity: $POLARITY"

      if [[ $POLARITY != dark || $THEME != default ]]; then
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch
      fi
    '';
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-dark";
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/standardized-dark.yaml";
    image = ../../../wallpapers/Astronaut.png;

    targets = {
      waybar.enable = false;
      vscode.enable = false;
      yazi.enable = true;
      firefox.profileNames = [userdata.username];
      firefox.firefoxGnomeTheme.enable = true;
    };

    targets.gnome.enable = lib.mkIf isLinux true;
    targets.kde.enable = lib.mkIf isLinux true;
    targets.gtk = lib.mkIf isLinux {
      enable = true;
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

  programs.vscode = let
    vscodeDarkTheme =
      if config.lib.stylix.colors.scheme-name == "Nord"
      then "Nord"
      else "Default Dark Modern";

    vscodeLightTheme =
      if config.lib.stylix.colors.scheme-name == "Nord Light"
      then "Nord Light"
      else "Default Light Modern";
  in {
    userSettings = {
      "window.autoDetectColorScheme" = true;
      "workbench.preferredDarkColorTheme" = vscodeDarkTheme;
      "workbench.preferredLightColorTheme" = vscodeLightTheme;
    };
  };

  home.file = {
    ".local/state/colors.json".source = config.lib.stylix.colors {
      template = ''
        {
          "theme":  "{{scheme}}",
          "slug":   "{{slug}}",
          "author": "{{author}}",
          "colors": {
            "color0": "#{{base00-hex}}",
            "color1": "#{{base01-hex}}",
            "color2": "#{{base02-hex}}",
            "color3": "#{{base03-hex}}",
            "color4": "#{{base04-hex}}",
            "color5": "#{{base05-hex}}",
            "color6": "#{{base06-hex}}",
            "color7": "#{{base07-hex}}",
            "color8": "#{{base08-hex}}",
            "color9": "#{{base09-hex}}",
            "color10": "#{{base0A-hex}}",
            "color11": "#{{base0B-hex}}",
            "color12": "#{{base0C-hex}}",
            "color13": "#{{base0D-hex}}",
            "color14": "#{{base0E-hex}}",
            "color15": "#{{base0F-hex}}"
          }
        }
      '';
      extension = ".json";
    };
  };
}
