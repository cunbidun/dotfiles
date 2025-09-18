{
  pkgs,
  inputs,
  config,
  ...
}: {
  programs.hyprpanel = {
    enable = true;

    settings = {
      bar = {
        wallpaper.image = "${config.stylix.image}";
        theme.matugen = true;
        workspaces = {
          ignored = "-\\d+";
          numbered_active_indicator = "highlight";
          show_icons = false;
          show_numbered = true;
          workspaces = 9;
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
          icon = "";
        };
        layouts = {
          "0" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = ["volume" "network" "bluetooth" "systray" "clock" "notifications"];
          };
          "1" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = ["volume" "clock" "notifications"];
          };
          "2" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = ["volume" "clock" "notifications"];
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
          outer_spacing = "1em";
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
            };
            media = {
              enableBorder = false;
            };
            windowtitle = {
              spacing = "1em";
            };
          };
          menus = {
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
        matugen = false;
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
