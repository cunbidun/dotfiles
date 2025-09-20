{
  pkgs,
  inputs,
  config,
  lib,
  userdata,
  ...
}: {
  programs.hyprpanel = {
    enable = true;
    package = inputs.hyprpanel.packages.${pkgs.system}.default;
    settings = {
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
            right = ["volume" "network" "bluetooth" "custom/volume" "hypridle" "systray" "clock" "notifications"];
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
          size = "14px";
          weight = "400";
          style = "normal";
        };
        notification = {
          border_radius = "0em";
        };
        osd = {
          radius = "0em";
        };
      };
    };
  };

  # One-shot service to restart hyprpanel
  systemd.user.services.hyprpanel-restart = {
    Unit = {
      Description = "Restart hyprpanel service";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart hyprpanel.service";
    };
  };

  # Path watcher to restart hyprpanel when config changes
  systemd.user.paths.hyprpanel-config-watcher = {
    Unit = {
      Description = "Watch hyprpanel config file for changes";
    };
    Path = {
      # Watch both the file and the directory to catch file recreations
      PathModified = "%h/.config/hyprpanel/config.json";
      PathChanged = "%h/.config/hyprpanel";
      Unit = "hyprpanel-restart.service";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.hyprpanel = {
    Service = {
      RestartSec = 1;
      TimeoutStopSec = 1;
    };
    Unit = {
      # Disable automatic restarts on config changes
      X-Restart-Triggers = lib.mkForce [];
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
    pulseaudio
  ];
}
