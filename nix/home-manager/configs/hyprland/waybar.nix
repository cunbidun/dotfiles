{
  config,
  pkgs,
  lib,
  project_root,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      {
        name = "waybar";
        layer = "top";
        height = 20;
        spacing = 4;
        modules-left = ["hyprland/workspaces" "hyprland/submap" "custom/mode"];
        modules-center = ["hyprland/window"];
        modules-right = [
          "network"
          "pulseaudio"
          # "bluetooth"
          "custom/brightness"
          "custom/weather"
          "custom/theme"
          "tray"
          "clock"
        ];
        "hyprland/window" = {
          tooltip = false;
        };
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "WEB";
            "6" = "EXTRA";
            "7" = "QUANT";
            "8" = "8";
            "9" = "VI";
          };
        };
        "hyprland/submap" = {
          format = "SUBMAP: {}";
          max-length = 30;
          tooltip = false;
        };
        tray.spacing = 0;
        clock = {
          format = "{:%a %b %d, %H:%M:%S}";
          interval = 1;
          tooltip = false;
        };
        bluetooth = {
          format = "BLUE {status}";
          format-alt = false;
          format-on = "BLUE";
          format-off = "[D] BLUE";
          on-click = "$TERMINAL -T '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e ${lib.getExe pkgs.bluetuith}";
          tooltip = false;
        };
        pulseaudio = {
          scroll-step = 5;
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% ";
          format-bluetooth-muted = "{icon} Muted ";
          format-muted = "{icon} Muted";
          format-icons = {
            default = ["VOL"];
          };
          on-click = "$TERMINAL -T '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e ${lib.getExe pkgs.pulsemixer}";
          tooltip = false;
        };
        network = {
          interval = 60;
          interface = "wlp0s20f3";
          format-wifi = "NET {essid} {signalStrength}%";
          format-ethernet = "NET {ipaddr}/{cidr}";
          format-linked = "NET {ifname} (No IP)";
          format-disconnected = "[D] NET";
          on-click = "$TERMINAL -T '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e nmtui";
          tooltip = false;
        };
        "custom/weather" = {
          interval = "once";
          exec = "${lib.getExe scripts.weather}";
          signal = 20;
          tooltip = false;
          format = "{}";
          on-click = "$TERMINAL -T '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e less -Srf \"$HOME/.cache/weatherreport\"";
          on-click-right = "${lib.getExe scripts.weather-sync}";
          on-click-middle = "${lib.getExe scripts.weather-sync}";
        };
        "custom/brightness" = {
          interval = "once";
          exec = "${lib.getExe scripts.brightness-control} get";
          signal = 16;
          tooltip = false;
          format = "BRT {}%";
        };
        "custom/mode" = {
          interval = "once";
          exec = "cat \${XDG_RUNTIME_DIR}/hypr/\${HYPRLAND_INSTANCE_SIGNATURE}/current_mode 2>/dev/null || echo 'normal'";
          signal = 17;
          tooltip = false;
          format = "MODE: {}";
        };
        "custom/theme" = {
          interval = 1;
          exec = "${lib.getExe scripts.get-theme-polarity}";
          tooltip = false;
          format = "{}";
          on-click = "${lib.getExe scripts.toggle-theme-debounced}";
        };
      }
    ];
  };

  xdg.configFile."waybar/style.css".text = ''
    /* begin_theme */
    /* darkplus theme */
    @define-color base00 #${config.lib.stylix.colors.base00};
    @define-color base01 #${config.lib.stylix.colors.base01};
    @define-color base02 #${config.lib.stylix.colors.base02};
    @define-color base03 #${config.lib.stylix.colors.base03};
    @define-color base04 #${config.lib.stylix.colors.base04};
    @define-color base05 #${config.lib.stylix.colors.base05};
    @define-color base06 #${config.lib.stylix.colors.base06};
    @define-color base07 #${config.lib.stylix.colors.base07};
    @define-color base08 #${config.lib.stylix.colors.base08};
    @define-color base09 #${config.lib.stylix.colors.base09};
    @define-color base0A #${config.lib.stylix.colors.base0A};
    @define-color base0B #${config.lib.stylix.colors.base0B};
    @define-color base0C #${config.lib.stylix.colors.base0C};
    @define-color base0D #${config.lib.stylix.colors.base0D};
    @define-color base0E #${config.lib.stylix.colors.base0E};
    @define-color base0F #${config.lib.stylix.colors.base0F};
    /* end_theme */

    * {
      transition: none;
      box-shadow: none;
    }

    #waybar {
    	font-family: 'SFMono Nerd Font';
    	font-size: 13px;
    	font-weight: 400;
      color: @base06;
      background: @base01;
    }

    /* workspaces */
    #workspaces {
      margin: 0 4px;
    }

    #workspaces button {
      padding: 0 5px;
      color: @base06;
      border-width: 0;
      font-weight: normal;
    }

    #workspaces button:hover {
      border-radius: 0px;
      background: @base06;
      color: @base01;
      border-width: 0;
    }

    #workspaces button.active {
      border-radius: 0px;
      background-color: @base0C;
      color: @base01;
      border-width: 0;
    }

    #workspaces button.urgent {
      border-radius: 0px;
      background-color: @base08;
      color: @base01;
      border-width: 0;
    }

    /* submap */
    #submap {
      padding: 0 4px;
    }

    #tray, .ibus-en, .ibus-vi, #network, #custom-audio_idle_inhibitor, #custom-brightness, #custom-mode, #custom-theme, #custom-weather, #mode, #pulseaudio, #clock, #bluetooth {
      margin: 0 2px;
      padding: 0 6px;
      min-width: 22px;
    }

    .output {
      color: @base09;
    }

    .ibus-vi {
      color: @base0D;
    }

    .ibus-en {
      color: @base09;
    }

    #tray {
      background-color: @base02;
    }

    #tray * {
      padding: 0 6px;
    }

    #tray *:first-child {
      border-left: none;
    }

    #pulseaudio.muted {
      color: @base08;
    }

    #pulseaudio.bluetooth {
      color: @base0C;
    }

    #clock {
      margin-left: 0px;
      margin-right: 4px;
    }
  '';
  home.activation = {
    waybar-restart = ''
      #!/usr/bin/env bash
      if [[ -v DBUS_SESSION_BUS_ADDRESS && -v XDG_RUNTIME_DIR ]]; then
        export PATH=${lib.makeBinPath [pkgs.systemdMinimal]}:$PATH
        systemctl --user restart waybar.service
      fi
    '';
  };
}
