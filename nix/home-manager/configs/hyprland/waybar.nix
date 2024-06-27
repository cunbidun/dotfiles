{
  pkgs,
  lib,
  project_root,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
in {
  xdg.configFile."waybar/config".text = ''
    {
      "name": "waybar",
      "layer": "top", // Waybar at top|bottom laye
      "height": 20, // Waybar height (to be removed for auto height)
      "spacing": 4, // Gaps between modules (4px)
      "modules-left": [
        "hyprland/workspaces",
        "hyprland/submap"
      ],
      "modules-center": [
        "hyprland/window"
      ],
      "modules-right": [
        "network",
        "pulseaudio",
        "bluetooth",
        "custom/brightness",
        "custom/weather",
        "custom/mode",
        "tray",
        "clock"
      ],
      // Modules configuration
      "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
          "1": "1",
          "2": "2",
          "3": "3",
          "4": "4",
          "5": "web",
          "6": "cp",
          "7": "quant",
          "8": "game",
          "9": "9",
        },
      },
      "hyprland/submap": {
        "format": "submap: {}",
        "max-length": 30,
        "tooltip": false
      },
      "tray": {
        "spacing": 0
      },
      "clock": {
        "format": "{:%a %b %d, %H:%M:%S}",
        "interval": 1,
      },
      "bluetooth": {
        "format-alt": false,
        "format-on": "",
        "format-off": "!",
        "on-click": "$TERMINAL -t '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e ${lib.getExe pkgs.bluetuith}",
        "tooltip": false,
      },
      "pulseaudio": {
        "scroll-step": 5, // %, can be a float
        "format": "{icon}: {volume}%",
        "format-bluetooth": "{icon}: {volume}% ",
        "format-bluetooth-muted": "{icon}: Muted ",
        "format-muted": "{icon}: Muted",
        "format-icons": {
          "headphone": "",
          "hands-free": "",
          "headset": "",
          "phone": "",
          "portable": "",
          "car": "",
          "default": [
            "[.]",
            "[v]",
            "[V]"
          ]
        },
        "on-click": "$TERMINAL -t '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e ${lib.getExe pkgs.pulsemixer}"
      },
      // https://github.com/Alexays/Waybar/wiki/Module:-Network
      "network": {
        "interval": 60,
        "interface": "wlp0s20f3", // (Optional) To force the use of this interface
        "format-wifi": "{essid} ({signalStrength}%)",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": false,
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "on-click": "$TERMINAL -t '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e nmtui"
      },
      "custom/weather": {
        "interval": "once",
        "exec-if": "which sc_weather",
        "exec": "sc_weather",
        "signal": 20,
        "tooltip": false,
        "format": "{}",
        "on-click": "$TERMINAL -t '__waybar_popup' -o window.dimensions.columns=160 -o window.dimensions.lines=40 -e less -Srf \"$HOME/.cache/weatherreport\"",
        "on-click-right": "${lib.getExe scripts.weather-sync}",
        "on-click-middle": "${lib.getExe scripts.weather-sync}"
      },
      "custom/brightness": {
        "interval": "once",
        "exec-if": "which sc_get_brightness_percentage",
        "exec": "sc_get_brightness_percentage",
        "signal": 16,
        "tooltip": false,
        "format": "BRT: {}%",
      },
      "custom/mode": {
        "interval": "once",
        "exec": "cat ''${XDG_RUNTIME_DIR}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/current_mode 2>/dev/null || echo 'normal'",
        "signal": 17,
        "tooltip": false,
        "format": "MODE: {}",
      },
    }
  '';
  xdg.configFile."waybar/style.css".text = ''
    /* begin_theme */
    /* darkplus theme */
    @define-color base00 #000000;
    @define-color base01 #1E1E1E;
    @define-color base02 #1E1E1E;
    @define-color base03 #444444;

    @define-color base04 #d8dee9;
    @define-color base05 #e5e9f0;
    @define-color base06 #e5e5e5;

    @define-color base07 #8fbcbb;
    @define-color base08 #88c0d0; /* cyan */
    @define-color base09 #4B95CF;
    @define-color base0A #0078D4;

    @define-color base0B #f14c4c; /* red */
    @define-color base0C #d08770;
    @define-color base0D #f5f543;
    @define-color base0E #a3be8c;
    @define-color base0F #b48ead;
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
    }

    #workspaces button:hover {
      border-radius: 0px;
      background: @base06;
      color: @base01;
      border-width: 0;
      border-radius: 4px;
    }

    #workspaces button.active {
      border-radius: 0px;
      background-color: @base08;
      color: @base01;
      border-width: 0;
      border-radius: 4px;
    }

    #workspaces button.urgent {
      border-radius: 0px;
      background-color: @base0C;
      color: @base01;
      border-width: 0;
      border-radius: 4px;
    }

    /* submap */
    #submap {
      padding: 0 4px;
      background-color: @base0E;
      border-radius: 4px;
      color: @base01;
    }

    #tray, .ibus-en, .ibus-vi, #network, #custom-audio_idle_inhibitor, #custom-brightness, #custom-mode, #custom-weather, #mode, #pulseaudio, #clock, #bluetooth {
      margin: 0 2px;
      padding: 0 6px;
      background-color: @base03;
      border-radius: 4px;
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
      background-color: @base0A;
    }

    #tray * {
      padding: 0 6px;
      /* border-left: 1px solid @base00; */
    }

    #tray *:first-child {
      border-left: none;
    }

    #pulseaudio.muted {
      color: @base0C;
    }

    #pulseaudio.bluetooth {
      color: @base0C;
    }

    #clock {
      margin-left: 0px;
      margin-right: 4px;
      background-color: @base03;
    }

  '';
}
