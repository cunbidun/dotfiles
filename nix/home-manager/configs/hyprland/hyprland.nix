# Source code: https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
# Example: https://github.com/spikespaz/dotfiles/tree/master/users/jacob/hyprland
{
  inputs,
  lib,
  pkgs,
  project_root,
  ...
}: let
  scripts = import "${project_root}/nix/home-manager/scripts.nix" {pkgs = pkgs;};
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
    settings = {
      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = [
        ",preferred,auto,1"
      ];

      exec-once = [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user reset-failed"
        "systemctl --user restart dbus.service"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start activitywatch.service"
      ];

      env = ["HYPRCURSOR_THEME,hyprcursor-phinger" "NIXOS_OZONE_WL,1"];

      misc = {
        enable_swallow = true;
        swallow_exception_regex = "wev|^(.*Yazi.*)$|ranger|^(.*nvim.*)$|^(.*Competitive Programming.*)$";
        swallow_regex = "^(Alacritty)$";
        disable_hyprland_logo = true;
        focus_on_activate = true;
      };
      debug = {
        disable_logs = true;
      };
      group = {
        groupbar = {
          font_family = "SFMono Nerd Font";
          font_size = 10;
          height = 15;
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
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
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

      gestures = {
        workspace_swipe = true;
        workspace_swipe_cancel_ratio = 0.1;
        workspace_swipe_distance = 100;
      };

      plugin = {
        hyprfocus = {
          enabled = true;
          animate_floating = true;
          animate_workspacechange = false;
          focus_animation = "shrink";
          bezier = "realsmooth, 0.28,0.29,.69,1.08";
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

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      windowrulev2 = [
        "nofocus,class:^(Conky)$"
        "noinitialfocus,class:^(Conky)$"
        "noborder,class:^(dota2)$"
        "noblur,class:^(dota2)$"
        "noshadow,class:^(dota2)$"
        "noborder,class:^(cs2)$"
        "noblur,class:^(cs2)$"
        "noshadow,class:^(cs2)$"
        "float,class:^(Caprine)$"
        "float,class:^(Spotify)$"
        "float,class:^(Signal)$"
        "float,class:^(obsidian)$"
        "float,class:^(org.gnome.NautilusPreviewer)$"
        "float,title:^(__scratchpad)$"
        "float,title:^(__waybar_popup)$"
        "float,class:^(xdg-desktop-portal-gtk)$"
        "float,title:^(Sign in.*Google Accounts.*)$"
        "noanim,class:^(ueberzugpp.*)$"
        "noanim,title:^(.*ueberzugpp.*)$"
        "stayfocused,class:^(tofi.*)$"
        "float,class:^(waydroid.com.*)$"
        "workspace 1 silent,class:^(Code)$,title:(.*dotfiles.*Visual Studio Code.*)"
        "workspace 8 silent,class:^(Steam)$"
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, ${lib.getExe scripts.increase-volume}"
        ",XF86AudioLowerVolume, exec, ${lib.getExe scripts.decrease-volume}"
        ",XF86AudioMute, exec, ${lib.getExe scripts.toggle-volume}"
      ];
    };

    plugins = [
      inputs.hyprfocus.packages.${pkgs.system}.hyprfocus
    ];

    extraConfig = ''
      autogenerated = 0 # remove this line to remove the warning

      # See https://wiki.hyprland.org/Configuring/Keywords/ for more
      $mainMod = SUPER

      # See https://wiki.hyprland.org/Configuring/Binds/ for more

      # Start Applications
      bind = $mainMod, Return, exec, alacritty
      bind = $mainMod, P, exec, tofi-drun
      bind = $mainMod, E, exec, nautilus
      bind = $mainMod SHIFT, D, exec, dotfiles_picker
      bind = $mainMod SHIFT, N, exec, nord_color_picker
      bind = $mainMod, M, exec, ${lib.getExe scripts.hyprland-mode}
      # bind = $mainMod, Space, exec, set_language

      # Clipboard
      bind = $mainMod SHIFT, S, exec, slurp | grim -g - - | wl-copy -t image/png
      bind = $mainMod, V, exec,  cliphist list | tofi --prompt-text "select clipboard:" --height=25% --horizontal=false --result-spacing=5 | cliphist decode | wl-copy

      bind = $mainMod, slash, layoutmsg, togglesplit
      bind = $mainMod, F, togglefloating,
      bind = $mainMod SHIFT, C, killactive,
      bind = $mainMod, backslash, exec, dunstctl close-all
      # bind = $mainMod SHIFT, Q, exec, touch ~/dotfiles/window_manager/hyprland/linux/.config/hypr/hyprland.conf

      # Media
      bindle=$mainMod, F1, exec, sc_brightness_change decrease 5
      bindle=$mainMod, F2, exec, sc_brightness_change increase 5

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
      bind = $mainMod CONTROL, M, exec, sc_hyprland_show_minimize

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
      bind = $mainMod SHIFT, M, exec, sc_hyprland_minimize

      # Scroll through existing workspaces with mainMod + scroll
      # bind = $mainMod, Tab, overview:toggle,

      # Group
      bind = $mainMod, t, togglegroup
      bind = $mainMod SHIFT, t, moveoutofgroup

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
      bind=,l,exec,loginctl lock-session
      bind=SHIFT,L,exec,sc_prompt 'Do you want to suspend?' 'sleep 0.6 && loginctl lock-session && sleep 1 && systemctl suspend -i'
      bind=$mainMod SHIFT, Q, exec, sc_prompt 'Do you want to exit?' 'systemctl --user stop hyprland.service'

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

    '';
  };
}