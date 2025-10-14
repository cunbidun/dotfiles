{
  config,
  inputs,
  pkgs,
  lib,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;

  # Theme configuration abstraction
  # Import from shared theme configuration
  # NOTE:
  themeConfigs = import ./shared/theme-configs.nix;

  # NOTE:
  # the specialisation name for theme must be named '{theme}-{polarity}'. Else switch won't work
  # By default, the default configuration is 'default-dark' (with 'default-light')

  # NOTE on priority
  # Helper                  | Priority it sets  | Typical use
  # lib.mkDefault value     | 1000              | Ship a safe default that users can override easily
  # lib.mkOverride N value  | N (you pick)      | Fine‑tune how strongly you want to win/lose merges
  # lib.mkForce value       | 50                | “Last word”—almost always beats everything else
  mkSpecializationConfig = theme: polarity: config: let
    colorScheme =
      if polarity == "light"
      then "prefer-light"
      else "prefer-dark";
  in {
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkOverride 1 colorScheme;
    services.vicinae.settings.theme.name = config.vicinaeTheme;
    stylix = {
      base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/${config.scheme}.yaml";
      image = lib.mkForce config.wallpaper;
    };
    home.activation.reconciliation_theme = lib.mkForce ''
      #!/usr/bin/env bash
      # no-op script to avoid double activation
    '';

    # Write the current theme name directly in the specialization
    home.file.".local/state/stylix/current-theme-name.txt".text = lib.mkForce "${theme}-${polarity}";
  };

  # Generate specializations for each theme/polarity combination
  generateSpecializations = lib.foldl' (
    acc: themeName: let
      themeConfig = themeConfigs.${themeName};
    in
      acc
      // (lib.mapAttrs' (
          polarity: config:
            lib.nameValuePair "${themeName}-${polarity}" {
              configuration = mkSpecializationConfig themeName polarity config;
            }
        )
        themeConfig)
  ) {} (lib.attrNames themeConfigs);

  # Generate nvim theme mappings from themeConfigs for both light and dark variants
  nvimThemeMappings = lib.foldl' (
    acc: themeName: let
      themeConfig = themeConfigs.${themeName};
    in
      acc
      // {
        # Map light variants
        "${themeName}-light" = themeConfig.light.nvimTheme;
        # Map dark variants
        "${themeName}-dark" = themeConfig.dark.nvimTheme;
      }
  ) {} (lib.attrNames themeConfigs);

  # Function to get scheme name from base16 scheme file
  getSchemeNameFromFile = schemeFile: let
    schemeContent = builtins.readFile "${pkgs.base16-schemes}/share/themes/${schemeFile}.yaml";
    # Extract scheme name from YAML (format: "name: \"Name\"")
    schemeMatch = builtins.match ".*name: \"([^\"]+)\".*" schemeContent;
  in
    if schemeMatch != null
    then builtins.head schemeMatch
    else schemeFile; # fallback to filename if parsing fails

  # Function to get VSCode theme from scheme name
  getVscodeTheme = schemeName: let
    # Get all theme configurations (both light and dark)
    allConfigs = lib.flatten (
      lib.mapAttrsToList (
        themeName: themeConfig:
          lib.mapAttrsToList (polarity: config: config) themeConfig
      )
      themeConfigs
    );
    # Find the matching theme config by inferred scheme name
    findThemeConfig =
      lib.findFirst (
        entry: (getSchemeNameFromFile entry.scheme) == schemeName
      )
      null
      allConfigs;
  in
    if findThemeConfig != null
    then findThemeConfig.vscodeTheme
    else "Default Dark Modern"; # fallback

  # Function to get HyprPanel theme from scheme name
  getHyprpanelTheme = schemeName: let
    # Get all theme configurations (both light and dark)
    allConfigs = lib.flatten (
      lib.mapAttrsToList (
        themeName: themeConfig:
          lib.mapAttrsToList (polarity: config: config) themeConfig
      )
      themeConfigs
    );
    # Find the matching theme config by inferred scheme name
    findThemeConfig =
      lib.findFirst (
        entry: (getSchemeNameFromFile entry.scheme) == schemeName
      )
      null
      allConfigs;
  in
    if findThemeConfig != null
    then findThemeConfig.hyprpanelTheme
    else "monochrome"; # fallback
in {
  services.darkman = {
    enable = isLinux;

    darkModeScripts = {
      dark-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/themectl set-polarity dark
      '';
    };
    lightModeScripts = {
      light-theme-switch = ''
        /etc/profiles/per-user/${userdata.username}/bin/themectl set-polarity light
      '';
    };

    settings = {
      usegeoclue = true;
    };
  };

  services.theme-manager = {
    enable = isLinux;
    enableTray = isLinux; # Enable tray icon on Linux systems
    themes = builtins.attrNames themeConfigs;
    nvimThemeMap = nvimThemeMappings;
    hookScriptContent = ''
      #!/usr/bin/env bash
      /etc/profiles/per-user/${userdata.username}/bin/theme-switch
    '';
  };

  # Apply the generated specializations
  specialisation = generateSpecializations;

  home.activation = {
    reconciliation_theme = lib.mkIf isLinux ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Running theme reconciliation..."
      POLARITY="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo dark)"   # 'dark' by default
      THEME="$(${pkgs.theme-manager}/bin/themectl get-theme 2>/dev/null || echo default)"  # 'default' by default
      echo "Detected theme: $THEME, polarity: $POLARITY"

      if [[ $POLARITY != dark || $THEME != default ]]; then
        /etc/profiles/per-user/${userdata.username}/bin/theme-switch
      fi
    '';
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-dark";
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${themeConfigs.default.dark.scheme}.yaml";
    image = themeConfigs.default.dark.wallpaper;

    targets =
      {
        waybar.enable = false;
        vscode.enable = false;
        yazi.enable = true;
        hyprlock.enable = true;
        fzf.enable = true;
        gnome.enable = lib.mkIf isLinux true;
        kde.enable = lib.mkIf isLinux true;
        gtk = lib.mkIf isLinux {
          enable = true;
        };
      }
      // lib.optionalAttrs (userdata.default_browser == "firefox") {
        firefox.profileNames = [userdata.username];
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

    fonts = lib.mkIf isLinux {
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

  programs.vscode = {
    profiles.default.userSettings = {
      "workbench.colorTheme" = getVscodeTheme config.lib.stylix.colors.scheme-name;
    };
  };

  programs.hyprpanel = {
    settings = lib.importJSON "${pkgs.hyprpanel}/share/themes/${getHyprpanelTheme config.lib.stylix.colors.scheme-name}.json";
  };

  wayland.windowManager.hyprland.settings.group.groupbar = {
    # white text on green background
    "col.active" = lib.mkForce "rgb(${config.lib.stylix.colors.base0C})";
    text_color = lib.mkForce "rgb(${config.lib.stylix.colors.base01})";

    # black text on light gray background
    "col.inactive" = lib.mkForce "rgb(${config.lib.stylix.colors.base01})";
    text_color_inactive = lib.mkForce "rgb(${config.lib.stylix.colors.base06})";
  };

  home.file = {
    # dump the themeConfigs as json for other programs to consume
    ".local/state/stylix/theme-config.json".text = builtins.toJSON themeConfigs;

    ".local/state/stylix/colors.json".source = config.lib.stylix.colors {
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

    # Default theme name for base configuration (will be overridden by specializations)
    ".local/state/stylix/current-theme-name.txt".text = "default-dark";
  };
}
