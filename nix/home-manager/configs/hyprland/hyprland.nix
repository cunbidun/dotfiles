# Source code: https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
# Example: https://github.com/spikespaz/dotfiles/tree/master/users/jacob/hyprland
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  scripts = import ../../scripts.nix {pkgs = pkgs;};
in {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
    settings = {
      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = [
        ",preferred,auto,1"
      ];

      ecosystem = {
        no_update_news = true; # disable news popup on startup
      };

      exec-once = [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "env > \${XDG_RUNTIME_DIR}/hypr/hyprland-runtime-env"
        "uwsm finalize"
      ];

      env = ["HYPRCURSOR_THEME,hyprcursor-phinger" "HYPRCURSOR_SIZE,24"];

      misc = {
        enable_swallow = true;
        swallow_exception_regex = "wev|^(.*[Yy]azi.*)$|ranger|^(.*nvim.*)$|^(.*Competitive Programming.*)$";
        disable_hyprland_logo = true;
        focus_on_activate = true;
      };
      debug = {
        disable_logs = true; # Set to true for production, false for debugging
      };
      group = {
        groupbar = {
          font_family = "SFMono Nerd Font";
          font_size = 13;
          indicator_height = 0;
          height = 21;
          rounding = 0;
          gradients = true; # draw the full background instead of us unlerlying indicator
        };
      };

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        repeat_rate = 50;
        repeat_delay = 200;
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
        sensitivity = 0;
      };

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.05, 1.05";
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 5, default, fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      master = {
        mfact = 0.5;
      };

      # See https://wiki.hypr.land/Configuring/Window-Rules/ for more
      windowrule = [
        # Game rules
        "match:class ^(dota2)$, decorate off"
        "match:class ^(dota2)$, no_blur on"
        "match:class ^(dota2)$, no_shadow on"
        "match:class ^(dota2)$, workspace 8 silent"
        "match:class ^(cs2)$, workspace 8 silent"
        "match:class ^(cs2)$, decorate off"
        "match:class ^(cs2)$, no_blur on"
        "match:class ^(cs2)$, no_shadow on"

        # Scratchpad rules
        "match:title ^(Spotify Premium)$, float on"
        "match:class ^([Ss]ignal)$, float on"
        "match:class ^(obsidian)$, float on"
        "match:title ^(Scratchpad)$, float on"
        "match:title ^(Open File)$, float on"
        "match:class ^(ueberzugpp.*)$, no_anim on"
        "match:title ^(.*ueberzugpp.*)$, no_anim on"
        "match:class ^(vicinae.*)$, stay_focused on"
        "match:title ^(Vicinae Launcher)$, stay_focused on"
        "match:title ^(Vicinae Launcher)$, decorate off"
        "match:class ^(Code)$ match:title (.*dotfiles.*Visual Studio Code.*), workspace 1 silent"
        "match:class ^([Ss]team)$, workspace 8 silent"

        # Messenger PWA
        "match:class ^(chrome-.*messenger.*)$, float on"

        # 1Password rules
        "match:class ^(.*1password.*)$, float on"
        "match:class ^(.*1password.*)$, pin on"
        "match:class ^(.*1password.*)$, center on"
        "match:class ^(.*1password.*)$, size 50% 50%"

        # File
        "match:title ^(FileChooser)$, float on"
        "match:title ^(FileChooser)$, pin on"
        "match:title ^(FileExplorer)$, float on"
        "match:class ^(xdg-desktop-portal-gtk)$, float on"
        "match:class ^(xdg-desktop-portal-gtk)$, pin on"

        # Waybar popup
        "match:title ^(Bluetooth Devices)$, float on"
        "match:title ^(__waybar_popup)$, size 50% 50%"
        "match:title ^(__waybar_popup)$, float on"
        "match:title ^(__waybar_popup)$, pin on"

        # WMs
        "match:class ^(spicy)$, float on"
        "match:class ^(spicy)$, decorate off"
        "match:class ^(spicy)$, no_blur on"
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, ${lib.getExe scripts.increase-volume}"
        ",XF86AudioLowerVolume, exec, ${lib.getExe scripts.decrease-volume}"
        ",XF86AudioMute, exec, ${lib.getExe scripts.toggle-volume}"
      ];

      plugin = {
        overview = {
          showNewWorkspace = false;
          exitOnSwitch = true;
          workspaceBorderSize = 3;
          workspaceActiveBorder = "rgb(88c0d0)";
          panelColor = "rgba(00000000)";
          affectStrut = true;
        };
        hyprfocus = {
          enabled = true;
          animate_floating = true;
          animate_workspacechange = false;
          focus_animation = "shrink";
          bezier = "realsmooth, 0.28,0.29,0.69,1.08";
          flash = {
            flash_opacity = 0.95;
          };
          shrink = {
            shrink_percentage = 0.99;
            in_bezier = "realsmooth";
            in_speed = 1;
            out_bezier = "realsmooth";
            out_speed = 2;
          };
        };
      };
    };

    plugins = [
      # inputs.hyprfocus.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus
      # inputs.Hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace
    ];

    extraConfig = ''
      autogenerated = 0

      # See https://wiki.hyprland.org/Configuring/Variables/
      # SHIFT CAPS CTRL/CONTROL ALT MOD2 MOD3 SUPER/WIN/LOGO/MOD4 MOD5
      $mainMod = SUPER

      # See https://wiki.hyprland.org/Configuring/Binds/ for more

      # Start Applications
      bind = $mainMod, Return, exec, $TERMINAL
      bind = $mainMod, P, exec, vicinae dmenu-apps
      bind = ALT, space, exec, vicinae toggle
      bind = CTRL, space, exec, vicinae toggle
      bind = $mainMod, M, exec, ${lib.getExe scripts.hyprland-mode}

      # Clipboard
      bind = $mainMod SHIFT, S, exec, slurp | grim -g - - | wl-copy -t image/png

      bind = $mainMod, slash, layoutmsg, togglesplit
      bind = $mainMod, F, togglefloating,
      bind = $mainMod SHIFT, C, killactive,
      bind = $mainMod, backslash, exec, makoctl dismiss -a
      # bind = $mainMod SHIFT, Q, exec, touch ~/dotfiles/window_manager/hyprland/linux/.config/hypr/hyprland.conf

      # Media
      bindle=,XF86MonBrightnessDown, exec, ${lib.getExe scripts.brightness-control} decrease 5
      bindle=,XF86MonBrightnessUp, exec, ${lib.getExe scripts.brightness-control} increase 5

      # Move focus with mainMod + arrow keys
      bind = $mainMod, h, movefocus, l
      bind = $mainMod, l, movefocus, r
      bind = $mainMod, k, movefocus, u
      bind = $mainMod, j, movefocus, d

      bind = $mainMod SHIFT, h, swapwindow, l
      bind = $mainMod SHIFT, l, swapwindow, r
      bind = $mainMod SHIFT, k, swapwindow, u
      bind = $mainMod SHIFT, j, swapwindow, d

      bind = $mainMod CONTROL, h, movewindow, l
      bind = $mainMod CONTROL, l, movewindow, r
      bind = $mainMod CONTROL, k, swapwindow, u
      bind = $mainMod CONTROL, j, swapwindow, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, w, workspace, 5
      bind = $mainMod, a, workspace, 6
      bind = $mainMod, q, workspace, 7
      bind = $mainMod, g, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod CONTROL, M, exec, ${lib.getExe scripts.toggle-minimize-window}

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspacesilent, 1
      bind = $mainMod SHIFT, 2, movetoworkspacesilent, 2
      bind = $mainMod SHIFT, 3, movetoworkspacesilent, 3
      bind = $mainMod SHIFT, 4, movetoworkspacesilent, 4
      bind = $mainMod SHIFT, w, movetoworkspacesilent, 5
      bind = $mainMod SHIFT, a, movetoworkspacesilent, 6
      bind = $mainMod SHIFT, q, movetoworkspacesilent, 7
      bind = $mainMod SHIFT, g, movetoworkspacesilent, 8
      bind = $mainMod SHIFT, 9, movetoworkspacesilent, 9
      bind = $mainMod SHIFT, M, exec, ${lib.getExe scripts.minimize-window}
      # bind = $mainMod, Tab, overview:toggle

      #-----------------------------------+
      # will start a submap called "group" |
      #-----------------------------------+
      bind = $mainMod, t, submap, group
      submap=group

      # Group operations
      bind=,t,togglegroup
      bind=,t,submap,reset
      bind=,o,moveoutofgroup
      bind=,o,submap,reset

      # Move into group (direction-based)
      bind=,h,moveintogroup,l
      bind=,h,submap,reset
      bind=,j,moveintogroup,d
      bind=,j,submap,reset
      bind=,k,moveintogroup,u
      bind=,k,submap,reset
      bind=,l,moveintogroup,r
      bind=,l,submap,reset

      # Navigate between windows in group
      bind=,n,changegroupactive,f
      bind=,p,changegroupactive,b

      # use escape to go back to the global submap
      bind=,escape,submap,reset

      # will reset the submap, meaning end the current one and return to the global one
      submap=reset

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
      bind = $mainMod, mouse:274, togglefloating, # middle
      bindm = $mainMod, mouse:274, resizewindow

      #-------------------------------------+
      # will start a submap called "resize" |
      #-------------------------------------+
      bind = $mainMod SHIFT,R,submap,resize
      submap=resize

      # sets repeatable binds for resizing the active window
      binde=,l,resizeactive,10 0
      binde=,h,resizeactive,-10 0
      binde=,k,resizeactive,0 -10
      binde=,j,resizeactive,0 10

      # Move focus with mainMod + arrow keys
      bind = $mainMod, h, movefocus, l
      bind = $mainMod, l, movefocus, r
      bind = $mainMod, k, movefocus, u
      bind = $mainMod, j, movefocus, d

      # use reset to go back to the global submap
      bind=,escape,submap,reset

      # will reset the submap, meaning end the current one and return to the global one
      submap=reset

      #--------------------------------------+
      # will start a submap called "session" |
      #--------------------------------------+
      bind = $mainMod CONTROL, S, exec, sleep 1 && hyprctl dispatch submap reset
      bind = $mainMod CONTROL,S,submap,session

      submap=session

      # sets repeatable binds for resizing the active window
      bind=,r,exec,hyprctl reload && notify-send -t 1000 'Hyprland reloaded'
      bind=$mainMod SHIFT, Q, exec, ${lib.getExe scripts.prompt} 'Do you want to exit?' 'uwsm stop'

      # use reset to go back to the global submap
      bind=,escape,submap,reset

      # will reset the submap, meaning end the current one and return to the global one
      submap=reset

      #--------------------------+
      # Start a windows property |
      #--------------------------+
      bind = $mainMod SHIFT,P,submap,property
      submap=property

      # sets repeatable binds for resizing the active window
      bind=,f,fullscreen
      bind=,s,pin

      # use reset to go back to the global submap
      bind=,escape,submap,reset

      # will reset the submap, meaning end the current one and return to the global one
      submap=reset

      #---------------------------+
      # Start a scratchpad submap |
      #---------------------------+
      bind = $mainMod, S, exec, sleep 1 && hyprctl dispatch submap reset
      bind = $mainMod, S, submap, scratchpad
      submap=scratchpad

      # sets repeatable binds for resizing the active window
      bind = , m, exec, pypr toggle spotify
      bind = , m, submap,reset
      bind = , s, exec, pypr toggle signal
      bind = , s, submap,reset
      bind = , escape, submap, reset

      # will reset the submap, meaning end the current one and return to the global one
      submap=reset

      # scratchpad
      bind = $mainMod, Grave, exec, pypr toggle term
      bind = $mainMod, c, exec, pypr toggle messenger
      bind = $mainMod, n, exec, pypr toggle obsidian
      bind = $mainMod, e, exec, pypr toggle file
    '';
  };
}
