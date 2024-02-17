{ pkgs, config, lib, project_root, ... }:

let
  # mkDerivation signature: https://blog.ielliott.io/nix-docs/mkDerivation.html
  # {
  #   # Core Attributes
  #   name: 	string
  #   pname?: 	string
  #   version?: 	string
  #   src: 	path
  #   # Building
  #   buildInputs?: 	list[derivation]
  #   buildPhase?: 	string
  #   installPhase?: 	string
  #   builder?: 	path
  #   # Nix shell
  #   shellHook?: 	string
  # }

  # runCommand implementation:
  #  runCommand' = stdenv: name: env: buildCommand: 
  #      stdenv.mkDerivation ({ 
  #        inherit name buildCommand; 
  #        passAsFile = [ "buildCommand" ]; 
  #      } // env); 
  nixGLWrap = pkg:
    pkgs.stdenv.mkDerivation ({
      pname = "${pkg.name}-nixgl-wrapper";
      version = "${pkg.version}";
      buildCommand = ''
        mkdir $out
        ln -s ${pkg}/* $out
        rm $out/bin
        mkdir $out/bin
        for bin in ${pkg}/bin/*; do
         wrapped_bin=$out/bin/$(basename $bin)
         echo "exec ${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL $bin  \"\$@\"" > $wrapped_bin
         chmod +x $wrapped_bin
        done
      '';
      passAsFile = [ "buildCommand" ];
    } // { });

  package_config = import ./packages.nix {
    pkgs = pkgs;
    nixGLWrap = nixGLWrap;
  };
  dircolors = import ./dircolors.nix;
  systemd_config = import ./systemd.nix {
    pkgs = pkgs;
    lib = lib;
    project_root = project_root;
  };
  bookmarks = [
    "file:///home/cunbidun/Documents"
    "file:///home/cunbidun/Music"
    "file:///home/cunbidun/Pictures"
    "file:///home/cunbidun/Videos"
    "file:///home/cunbidun/Downloads"
    "file:///home/cunbidun/competitive_programming/output"
    "file:///home/cunbidun/Documents/Profile/green_card"
    "file:///home/cunbidun/.wallpapers"
  ];
  # color-scheme = import ./colors/vscode-dark.nix;
  color-scheme = import ./colors/nord.nix;
  swaylock-settings = import ./configs/swaylock.nix { color-scheme = color-scheme; };
  alacritty-settings = import ./configs/alacritty.nix { color-scheme = color-scheme; };
in with pkgs.stdenv;
with lib; {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = if isDarwin then "/Users/cunbidun" else "/home/cunbidun";

  home.packages = if isDarwin then
    package_config.default_packages ++ package_config.mac_packages
  else
    package_config.default_packages ++ package_config.linux_packages ++ package_config.x_packages
    ++ package_config.wayland_packages;

  # +--------------------+
  # |    Linux Config    | 
  # +--------------------+
  fonts.fontconfig.enable = true;

  xresources = {
    extraConfig = ''
      ! Copyright (c) 2016-present Arctic Ice Studio <development@arcticicestudio.com>
      ! Copyright (c) 2016-present Sven Greb <code@svengreb.de>

      ! Project:    Nord XResources
      ! Version:    0.1.0
      ! Repository: https://github.com/arcticicestudio/nord-xresources
      ! License:    MIT

      #define nord0 #2E3440
      #define nord1 #3B4252
      #define nord2 #434C5E
      #define nord3 #4C566A
      #define nord4 #D8DEE9
      #define nord5 #E5E9F0
      #define nord6 #ECEFF4
      #define nord7 #8FBCBB
      #define nord8 #88C0D0
      #define nord9 #81A1C1
      #define nord10 #5E81AC
      #define nord11 #BF616A
      #define nord12 #D08770
      #define nord13 #EBCB8B
      #define nord14 #A3BE8C
      #define nord15 #B48EAD
    '';
    properties = {
      "*.foreground" = "nord4";
      "*.background" = "nord0";
      "*.cursorColor" = "nord4";
      "*fading" = "35";
      "*fadeColor" = "nord3";

      "*.color0" = "nord1";
      "*.color1" = "nord11";
      "*.color2" = "nord14";
      "*.color3" = "nord13";
      "*.color4" = "nord9";
      "*.color5" = "nord15";
      "*.color6" = "nord8";
      "*.color7" = "nord5";
      "*.color8" = "nord3";
      "*.color9" = "nord11";
      "*.color10" = "nord14";
      "*.color11" = "nord13";
      "*.color12" = "nord9";
      "*.color13" = "nord15";
      "*.color14" = "nord7";
      "*.color15" = "nord6";

      # Rofi
      "rofi.kb-row-up" = "Up,Control+k,Shift+Tab,Shift+ISO_Left_Tab";
      "rofi.kb-row-down" = "Down,Control+j,Alt+Tab";
      "rofi.kb-accept-entry" = "Control+m,Return,KP_Enter,Alt+q";
      "rofi.terminal" = "mate-terminal";
      "rofi.kb-remove-to-eol" = "Control+Shift+e";
      "rofi.kb-mode-next" = "Shift+Right,Control+Tab,Control+l";
      "rofi.kb-mode-previous" = "Shift+Left,Control+Shift+Tab,Control+h";
      "rofi.kb-remove-char-back" = "BackSpace";

      # cursor
      "Xcursor.size" = "24"; # note, this must match the gtk theme
      "Xcursor.theme" = "macOS-Monterey";

      # dwm
      "dwm.borderpx" = "2";
      "dwm.scheme_sym_bg" = "nord4";
      "dwm.scheme_sym_fg" = "nord0";

      "Xft.dpi" = "100";
    };
  };

  home.file = if isLinux then {
    ".xinitrc".source = "${project_root}/xinitrc/.xinitrc";
    ".local/bin/dwm_wrapped".source = "${project_root}/window_manager/dwm/common/dwm_wrapped";

    ".local/bin/hyprland_wrapped".source = "${project_root}/window_manager/hyprland/linux/hyprland_wrapped";
    ".config/waybar/".source = "${project_root}/window_manager/hyprland/linux/.config/waybar";
    ".config/hypr/pyprland.toml".source = "${project_root}/window_manager/hyprland/linux/.config/hypr/pyprland.toml";
    ".config/hypr/hyprpaper.conf".source = "${project_root}/window_manager/hyprland/linux/.config/hypr/hyprpaper.conf";
    ".config/tofi/config".source = "${project_root}/util/tofi/linux/.config/tofi/config";
    ".config/dunst/dunstrc".source = "${project_root}/dunst/dunstrc";
    ".config/tmuxinator".source = "${project_root}/util/tmuxinator";
    ".tmux.conf".source = "${project_root}/util/tmux/.tmux.conf";

    #######################
    # lvim configurations #
    #######################
    ".config/lvim/lua".source = "${project_root}/text_editor/lvim/lua";
    ".config/lvim/snippet".source = "${project_root}/text_editor/lvim/snippet";
    ".config/lvim/config.lua".source = "${project_root}/text_editor/lvim/config.lua";
    ".config/lvim/cp.vim".source = "${project_root}/text_editor/lvim/cp.vim";
    ".config/lvim/markdown-preview.vim".source = "${project_root}/text_editor/lvim/markdown-preview.vim";

    ".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/themes";
    ".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/icons";
    ".fonts".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/fonts";
    ".config/swaylock/config".text = swaylock-settings.settings;
   
    ".local/bin/clock".source = "${project_root}/local/linux/.local/bin/clock";
    ".local/bin/colors-name.txt".source = "${project_root}/local/linux/.local/bin/colors-name.txt";
    ".local/bin/decrease_volume".source = "${project_root}/local/linux/.local/bin/decrease_volume";
    ".local/bin/dotfiles.txt".source = "${project_root}/local/linux/.local/bin/dotfiles.txt";
    ".local/bin/dotfiles_picker".source = "${project_root}/local/linux/.local/bin/dotfiles_picker";
    ".local/bin/get_cpu".source = "${project_root}/local/linux/.local/bin/get_cpu";
    ".local/bin/get_internet".source = "${project_root}/local/linux/.local/bin/get_internet";
    ".local/bin/get_language".source = "${project_root}/local/linux/.local/bin/get_language";
    ".local/bin/get_memory".source = "${project_root}/local/linux/.local/bin/get_memory";
    ".local/bin/get_temp".source = "${project_root}/local/linux/.local/bin/get_temp";
    ".local/bin/get_volume".source = "${project_root}/local/linux/.local/bin/get_volume";
    ".local/bin/increase_volume".source = "${project_root}/local/linux/.local/bin/increase_volume";
    ".local/bin/nord_color_picker".source = "${project_root}/local/linux/.local/bin/nord_color_picker";
    ".local/bin/sc_brightness_change".source = "${project_root}/local/linux/.local/bin/sc_brightness_change";
    ".local/bin/sc_calcurse_sync".source = "${project_root}/local/linux/.local/bin/sc_calcurse_sync";
    ".local/bin/sc_get_brightness".source = "${project_root}/local/linux/.local/bin/sc_get_brightness";
    ".local/bin/sc_get_brightness_percentage".source = "${project_root}/local/linux/.local/bin/sc_get_brightness_percentage";
    ".local/bin/sc_hyprland_count_minimized.py".source = "${project_root}/local/linux/.local/bin/sc_hyprland_count_minimized.py";
    ".local/bin/sc_hyprland_minimize".source = "${project_root}/local/linux/.local/bin/sc_hyprland_minimize";
    ".local/bin/sc_hyprland_show_minimize".source = "${project_root}/local/linux/.local/bin/sc_hyprland_show_minimize";
    ".local/bin/sc_lvim_update".source = "${project_root}/local/linux/.local/bin/sc_lvim_update";
    ".local/bin/sc_pacman_sync".source = "${project_root}/local/linux/.local/bin/sc_pacman_sync";
    ".local/bin/sc_remove_calcurse_dup".source = "${project_root}/local/linux/.local/bin/sc_remove_calcurse_dup";
    ".local/bin/sc_toggle_picom".source = "${project_root}/local/linux/.local/bin/sc_toggle_picom";
    ".local/bin/sc_weather".source = "${project_root}/local/linux/.local/bin/sc_weather";
    ".local/bin/sc_weather_sync".source = "${project_root}/local/linux/.local/bin/sc_weather_sync";
    ".local/bin/sc_window_picker".source = "${project_root}/local/linux/.local/bin/sc_window_picker";
    ".local/bin/toggle_volume".source = "${project_root}/local/linux/.local/bin/toggle_volume";
  } else
    { };

  dconf = if isLinux then {
    enable = true;
    settings = {
      # "org/nemo/preferences" = {
      #   show-hidden-files = true;
      # };
      # "org/cinnamon/desktop/default-applications/terminal" = {
      #   exec = "alacritty";
      #   exec-arg = "-e";
      # };
      "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    };
  } else
    { };

  gtk = if isLinux then {
    enable = true;
    gtk3 = {
      extraConfig = {
        gtk-font-name = "Cantarell 11";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "none";
      };
      bookmarks = bookmarks;
    };
    gtk4 = {
      extraConfig = {
        gtk-font-name = "Cantarell 11";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "none";
      };
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    cursorTheme = {
      package = pkgs.apple-cursor;
      name = "macOS-Monterey";
      size = 24;
    };
    iconTheme = {
      package = pkgs.papirus-nord;
      name = "Papirus-Dark";
    };
  } else
    { };

  xdg.mimeApps = if isLinux then {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
      "image/jpeg" = [ "feh.desktop" ];
      "image/png" = [ "feh.desktop" ];
      "text/plain" = [ "lvim.desktop" ];
      "inode/directory" = [ "org.gnome.nautilus.desktop" ];
      "text/html" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/about" = ["firefox.desktop"];
      "x-scheme-handler/unknown" = ["firefox.desktop"];
    };
  } else
    { };

  systemd.user = systemd_config;
  home.sessionVariables = if isLinux then {
    # Setting this is to local the .desktop files
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$HOME/.local/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS";
    PICKER = "tofi";
    TERMINAL = "alacritty";
    GTK_THEME = "Adwaita-dark";
  } else
    { };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-unikey fcitx5-gtk ];
  };

  # +--------------------+
  # |    Common conifg   |
  # +--------------------+

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      cdnote = "cd $HOME/note";
      s = "source $HOME/.zshrc";
      CP = "$HOME/competitive_programming/";
      r = "ranger";
      ls = "exa -la";
      cat = "bat";
      tree = "tree -a";

      # vim;
      vi = "lvim";
      nvim = "lvim";
      vim = "lvim";
    };
    initExtra = ''
      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim
      . $HOME/dotfiles/zsh/zshpath
      . $HOME/dotfiles/zsh/zshtheme
    '' + (if isLinux then ''
      export BAT_STYLE="plain"
      export BAT_THEME="${color-scheme.bat_theme}"
      export BAT_OPTS="--color always"
      export FZF_DEFAULT_OPTS="${color-scheme.fzf_default_opts}"
    '' else
      "");
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = dircolors.settings;
  };
  programs.alacritty = {
    enable = true;
    # package = (nixGLWrap pkgs.alacritty);
    package = pkgs.alacritty;
    settings = alacritty-settings.settings;
  };
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  #   configPackages = [ pkgs.hyprland ];
  # };
  # https://github.com/spikespaz/dotfiles/tree/master/users/jacob/hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    extraConfig = ''
########################################################################################
AUTOGENERATED HYPR CONFIG.
PLEASE USE THE CONFIG PROVIDED IN THE GIT REPO /examples/hypr.conf AND EDIT IT,
OR EDIT THIS ONE ACCORDING TO THE WIKI INSTRUCTIONS.
########################################################################################

#
# Please note not all available settings / options are set here.
# For a full list, see the wiki
#

autogenerated = 0 # remove this line to remove the warning

# See https://wiki.hyprland.org/Configuring/Monitors/
# monitor=eDP-1,3024x1890@120.000000,auto,1.6
monitor=,preferred,auto,1


# Execute your favorite apps at launch
exec-once = wl-paste --type text --watch cliphist store #Stores only text data
exec-once = wl-paste --type image --watch cliphist store #Stores only image data

# See https://wiki.hyprland.org/Configuring/Keywords/ for more
# exec = 

# Source a file (multi-file configs)
# source = ~/.config/hypr/myColors.conf

# Some default env vars.
env = XCURSOR_SIZE,24

# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    repeat_rate = 50 
    repeat_delay = 200  

    follow_mouse = 1
    touchpad {
        natural_scroll = yes 
    }

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}

general {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    gaps_in = 5
    gaps_out = 5
    border_size = 2
    col.active_border = rgb(88c0d0) rgb(88c0d0) 45deg
    col.inactive_border = rgb(3b4252)

    layout = dwindle
}

misc {
    enable_swallow = true
    swallow_exception_regex=wev|ranger
    swallow_regex = ^(Alacritty)$
    disable_hyprland_logo = true
}

decoration {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    rounding = 0 

    blur {
        enabled = true
        size = 3
        passes = 1
    }

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes 

    # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    bezier = myBezier, 0.05, 0.9, 0.05, 1.05

    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 5, default, fade
}

dwindle {
    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    pseudotile = yes # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = yes # you probably want this
    force_split = 2
}

master {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    new_is_master = false 
    mfact = 0.5
}

gestures {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = on 
    workspace_swipe_cancel_ratio = 0.1
    workspace_swipe_distance = 100 
}

# Example per-device config
# See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
device:epic-mouse-v1 {
    sensitivity = -0.5
}

group {
    groupbar {
        font_family = SauceCodePro Nerd Font Mono
        text_color = rgb(2E3440)
        font_size = 10
        height = 15
        col.inactive = rgb(ECEFF4) rgb(ECEFF4) 90deg  
        col.active = rgb(88c0d0) rgb(88c0d0) 90deg  
    }
    col.border_active = rgb(88c0d0)
    col.border_inactive = rgb(3b4252)
}

# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
windowrulev2 = nofocus,class:^(Conky)$
windowrulev2 = noinitialfocus,class:^(Conky)$

windowrulev2 = noborder,class:^(dota2)$
windowrulev2 = noblur,class:^(dota2)$
windowrulev2 = noshadow,class:^(dota2)$
windowrulev2 = noborder,class:^(cs2)$
windowrulev2 = noblur,class:^(cs2)$
windowrulev2 = noshadow,class:^(cs2)$

windowrulev2 = float,class:^(Caprine)$
windowrulev2 = float,class:^(Spotify)$
windowrulev2 = float,class:^(Signal)$
windowrulev2 = float,class:^(obsidian)$
windowrulev2 = float,class:^(org.gnome.NautilusPreviewer)$
windowrulev2 = float,title:^(__scratchpad)$
windowrulev2 = float,title:^(__waybar_popup)$
windowrulev2 = noanim,class:^(ueberzugpp.*)$
windowrulev2 = stayfocused,class:^(tofi.*)$


# See https://wiki.hyprland.org/Configuring/Keywords/ for more
$mainMod = SUPER 

# See https://wiki.hyprland.org/Configuring/Binds/ for more

# Start Applications
bind = $mainMod, Return, exec, alacritty 
bind = $mainMod, P, exec, tofi-drun
bind = $mainMod, E, exec, nautilus 
bind = $mainMod SHIFT, D, exec, dotfiles_picker 
bind = $mainMod SHIFT, N, exec, nord_color_picker 
# bind = $mainMod, Space, exec, set_language 

# Clipboard
bind = $mainMod SHIFT, S, exec, slurp | grim -g - - | wl-copy -t image/png
bind = $mainMod, V, exec,  cliphist list | tofi --prompt-text "select clipboard:" --height=25% --horizontal=false --result-spacing=5 | cliphist decode | wl-copy

bind = $mainMod, Z, layoutmsg, togglesplit
bind = $mainMod, F, togglefloating, 
bind = $mainMod SHIFT, C, killactive, 
bind = $mainMod, B, exec, pypr expose
bind = $mainMod, backslash, exec, dunstctl close-all
# bind = $mainMod SHIFT, Q, exec, touch ~/dotfiles/window_manager/hyprland/linux/.config/hypr/hyprland.conf

# Media
bindle=,XF86AudioRaiseVolume, exec, increase_volume
bindle=,XF86AudioLowerVolume, exec, decrease_volume
bindle=,XF86AudioMute, exec, toggle_volume 
bindle=,F12, exec, increase_volume
bindle=,F11, exec, decrease_volume
bindle=,F10, exec, toggle_volume 
bindle=,F12, exec, increase_volume
bindle=,F1, exec, sc_brightness_change decrease 5
bindle=,F2, exec, sc_brightness_change increase 5

# scratchpad
bind = $mainMod, Grave, exec, pypr toggle term 
bind = $mainMod, c, exec, pypr toggle messenger
bind = $mainMod, m, exec, pypr toggle spotify 
bind = $mainMod, s, exec, pypr toggle signal 
bind = $mainMod, n, exec, pypr toggle obsidian

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
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Group
bind = $mainMod, t, togglegroup

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
bind = $mainMod, mouse:274, togglefloating, # middle
bindm = $mainMod, mouse:274, resizewindow

# will switch to a submap called resize
bind = $mainMod SHIFT,R,submap,resize

#######################################
# will start a submap called "resize" #
#######################################
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

# will switch to a submap called resize
bind = $mainMod CONTROL,S,submap,session

########################################
# will start a submap called "session" #
########################################
submap=session

# sets repeatable binds for resizing the active window
bind=,l,exec,swaylock
bind=SHIFT,L,exec,sc_prompt 'Do you want to suspend?' 'sleep 0.6 && swaylock --daemonize && sleep 1 && systemctl suspend -i'
bind=$mainMod SHIFT, Q, exec, sc_prompt 'Do you want to exit?' 'systemctl --user stop hyprland.service'

# use reset to go back to the global submap
bind=,escape,submap,reset 

# will reset the submap, meaning end the current one and return to the global one
submap=reset

############################
# Start a windows property #
############################
bind = $mainMod SHIFT,P,submap,property
submap=property

# sets repeatable binds for resizing the active window
bind=,f,fullscreen
bind=,s,pin
bind=SHIFT,f,fakefullscreen

# use reset to go back to the global submap
bind=,escape,submap,reset 

# will reset the submap, meaning end the current one and return to the global one
submap=reset
'';
  };
}
