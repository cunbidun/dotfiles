{
  pkgs,
  inputs,
  config,
  lib,
  userdata,
  ...
}: let
  # Import centralized theme configuration
  themeConfigs = import ./shared/theme-configs.nix;

  # Function to get scheme name from base16 scheme file (same as in stylix.nix)
  getSchemeNameFromFile = schemeFile: let
    schemeContent = builtins.readFile "${pkgs.base16-schemes}/share/themes/${schemeFile}.yaml";
    # Extract scheme name from YAML (format: "name: \"Name\"")
    schemeMatch = builtins.match ".*name: \"([^\"]+)\".*" schemeContent;
  in
    if schemeMatch != null
    then builtins.head schemeMatch
    else schemeFile; # fallback to filename if parsing fails

  # Get hyprpanel theme from current stylix scheme
  getHyprPanelThemeFromStylix = let
    # Get all theme configurations (both light and dark)
    allConfigs = lib.flatten (
      lib.mapAttrsToList (
        themeName: themeConfig:
          lib.mapAttrsToList (polarity: config:
            config
            // {
              _themeName = themeName;
              _polarity = polarity;
            })
          themeConfig
      )
      themeConfigs
    );

    # Get current scheme from stylix (extract basename without .yaml extension)
    currentScheme = let
      schemePath = config.stylix.base16Scheme;
      schemeFile = baseNameOf schemePath;
      schemeNameWithoutExt =
        if lib.hasSuffix ".yaml" schemeFile
        then lib.removeSuffix ".yaml" schemeFile
        else schemeFile;
    in
      schemeNameWithoutExt;

    # Find the matching theme config by scheme name
    findThemeConfig = lib.findFirst (entry: entry.scheme == currentScheme) null allConfigs;
  in
    if findThemeConfig != null
    then findThemeConfig.hyprpanelTheme
    else "monochrome"; # fallback

  # Load the appropriate theme
  theme = lib.importJSON "${pkgs.hyprpanel}/share/themes/${getHyprPanelThemeFromStylix}.json";
in {
  programs.hyprpanel = {
    enable = true;

    settings = lib.recursiveUpdate theme {
      bar = {
        customModules = {
          polarity = {
            icon = {
              dark = "";
              light = "";
            };
            label = "{}";
            tooltip = "Click to toggle theme polarity";
            execute = "darkman get";
            executeOnAction = "darkman toggle";
            interval = 1000;
            actions = {
              onLeftClick = "darkman toggle";
            };
          };
        };
        workspaces = {
          ignored = "-\\d+";
          numbered_active_indicator = "highlight";
          show_icons = false;
          show_numbered = true;
          workspaces = 9;
          spacing = 1;
        };
        autoHide = "never";
        notifications = {
          show_total = false;
          hideCountWhenZero = false;
        };
        media = {
          show_label = true;
        };
        network = {
          truncation_size = 15;
        };
        launcher = {
          icon = "";
        };
        layouts = {
          "0" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = ["volume" "network" "bluetooth" "polarity" "hypridle" "systray" "clock" "notifications"];
          };
        };
      };

      menus = {
        clock = {
          time = {
            hideSeconds = false;
            military = false;
          };
          weather = {
            enabled = true;
            location = "10001";
            unit = "metric";
            key = "18314f574825468496c183537250502";
          };
        };
        media = {
          displayTime = false;
        };
        volume = {
          raiseMaximumVolume = true;
        };
        dashboard = {
          shortcuts = {
            left = {
              shortcut1 = {
                command = "firefox";
                tooltip = "Firefox";
              };
              shortcut4 = {
                command = "tofi-drun";
              };
            };
          };
        };
      };

      theme = {
        bar = {
          transparent = false;
          floating = false;
          enableShadow = false;
          outer_spacing = "0.5em";
          border = {
            width = "0em";
          };
          buttons = {
            radius = "0em";
            padding_x = "0.7rem";
            padding_y = "0em";
            y_margins = "0.1em";
            separator = {
              margins = "0.15em";
            };
            workspaces = {
              enableBorder = false;
              numbered_active_highlight_border = "0em";
              numbered_active_highlight_padding = "0.4em";
              numbered_inactive_padding = "0.4em";
              fontSize = "1em";
            };
            media = {
              enableBorder = false;
            };
            windowtitle = {
              spacing = "1em";
            };
            modules.hypridle.spacing = "0.5em";
          };
          menus = {
            card_radius = "0em";
            border = {
              radius = "0em";
              size = "0em";
            };
            popover = {
              radius = "0em";
            };
            tooltip = {
              radius = "0em";
            };
            scroller = {
              radius = "0em";
            };
            slider = {
              slider_radius = "0rem";
              progress_radius = "0rem";
            };
            progressbar = {
              radius = "0rem";
            };
            buttons = {
              radius = "0em";
            };
            switch = {
              radius = "0em";
              slider_radius = "0em";
            };
            menu = {
              media = {
                scaling = 100;
              };
              notifications = {
                scaling = 100;
              };
              clock = {
                scaling = 100;
              };
              dashboard = {
                profile = {
                  radius = "0em";
                };
              };
              power = {
                scaling = 90;
              };
            };
          };
        };
        font = {
          name = "SFMono Nerd Font";
          label = "SFMono Nerd Font Medium";
          size = "13px";
          weight = "400";
          style = "normal";
        };
        notification = {
          border_radius = "0em";
        };
        osd = {
          location = "top";
          radius = "0em";
        };
      };
    };
  };

  # Add missing required dependencies for HyprPanel
  home.packages = with pkgs; [
    # Required dependencies
    libgtop
    gnome.gvfs
    gtksourceview # gtksourceview3 maps to gtksourceview
    libsoup_3 # libsoup3 maps to libsoup_3

    # Optional dependencies
    python312Packages.gpustat # python-gpustat for GPU usage tracking
    wf-recorder # For built-in screen recorder
    power-profiles-daemon # Switch power profiles
  ];
}
