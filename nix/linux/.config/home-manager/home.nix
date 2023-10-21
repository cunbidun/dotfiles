{ config, pkgs, ... }:

let
  pkgsUnstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";
  home.packages = [                               
    pkgs.neovim

    # Messaging
    pkgs.signal-desktop

    # Utils
    pkgs.bat
    pkgs.eza
    pkgs.htop
    pkgs.fzf
    pkgs.ranger
    pkgs.neofetch
    pkgs.tree
    pkgs.espanso
    pkgs.tmux pkgs.tmuxinator
    pkgs.wget
    pkgs.wget
    pkgs.ncdu
    pkgs.xfce.thunar

    # Theme
    pkgs.lxappearance

    # For vim
    pkgs.shellcheck

    pkgsUnstable._1password-gui
    pkgsUnstable._1password
  ];

  home.file.".themes".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/themes";
  home.file.".icons".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nix-profile/share/icons";

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
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintmedium";
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
