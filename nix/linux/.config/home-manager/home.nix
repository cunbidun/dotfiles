{ config, ... }:

let
  pkgs = import <nixpkgs> {  config = { allowUnfree = true; }; };
  pkgsUnstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";
  home.packages = [                               
    # Text editor
    pkgsUnstable.vscode

    # Broswer
    pkgsUnstable.google-chrome
    pkgsUnstable.firefox

    # Font
    pkgsUnstable.liberation_ttf
    pkgsUnstable.cantarell-fonts
    pkgsUnstable.noto-fonts-color-emoji

    # Games
    pkgsUnstable.minecraft

    # Messaging
    pkgs.signal-desktop

    # Note
    pkgsUnstable.obsidian

    # Utils
    pkgs.bat # cat
    pkgs.eza # ls
    pkgs.htop
    pkgs.fzf
    pkgs.ranger pkgsUnstable.ueberzugpp
    pkgs.neofetch
    pkgs.tree
    pkgs.espanso
    pkgs.tmux pkgs.tmuxinator
    pkgs.wget
    pkgs.ncdu
    pkgs.xfce.thunar
    pkgs.evince
    pkgs.jq

    # Programming
    pkgsUnstable.cargo
    pkgsUnstable.zulu # OpenJDK for Java
    
    # Music player
    pkgs.spotify

    # Theme
    pkgs.lxappearance
    pkgsUnstable.bazel

    # For vim
    pkgs.shellcheck
    pkgsUnstable.shfmt

    # WMs
    pkgs.quickemu

    pkgsUnstable._1password-gui
    pkgsUnstable._1password
  ];

  fonts.fontconfig.enable = true;

  home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/themes";
  home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/icons";
  home.file.".fonts".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/fonts";

  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
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
      "rofi.kb-row-up" =                      "Up,Control+k,Shift+Tab,Shift+ISO_Left_Tab";
      "rofi.kb-row-down" =                    "Down,Control+j,Alt+Tab";
      "rofi.kb-accept-entry" =                "Control+m,Return,KP_Enter,Alt+q";
      "rofi.terminal" =                       "mate-terminal";
      "rofi.kb-remove-to-eol" =               "Control+Shift+e";
      "rofi.kb-mode-next" =                   "Shift+Right,Control+Tab,Control+l";
      "rofi.kb-mode-previous" =               "Shift+Left,Control+Shift+Tab,Control+h";
      "rofi.kb-remove-char-back" =            "BackSpace";

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
  home.file.".xinitrc".source = "${config.home.homeDirectory}/dotfiles/xinitrc/.xinitrc";

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
      theme = "robbyrussell";
    };
    shellAliases = {
      cdnote="cd $HOME/note";
      s="source $HOME/.zshrc";
      CP="$HOME/competitive_programming/";
      r="ranger";
      ls="exa -la";
      cat="bat";
      tree="tree -a";

      # vim;
      vi="lvim";
      nvim="lvim";
      vim="lvim";
    };
    initExtra = ''
      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim
      . $HOME/dotfiles/zsh/zshpath
      . $HOME/dotfiles/zsh/zshtheme
      . $HOME/dotfiles/zsh/zshconda
    '';
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  gtk = {
    enable = true;
    gtk3 = {
      extraConfig = {
        gtk-font-name = "Cantarell 11";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "none";
      };
    };
    theme = {
      name = "Nordic-darker-standard-buttons";
      package = pkgs.nordic;
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
  };
}