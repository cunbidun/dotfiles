let
  pkgs = import <nixpkgs> { config = { allowUnfree = true; }; };
  pkgsUnstable =
    import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
in {
  default_packages = [
    # Utils
    pkgs.bat # cat
    pkgs.eza # ls
    pkgs.htop
    pkgs.fzf
    pkgs.neofetch
    pkgs.tree
    pkgs.espanso
    pkgs.tmux
    pkgs.tmuxinator
    pkgs.wget
    pkgs.jq
    pkgs.ncdu
    pkgs.zip
    pkgs.unzip
    pkgsUnstable.newsboat

    pkgsUnstable.nixfmt
    pkgsUnstable.bazel

    # For vim
    pkgs.shellcheck
    pkgsUnstable.shfmt
  ];

  wayland_packages = [
    # Hyprland
    pkgsUnstable.waybar
    pkgsUnstable.hyprpaper
    pkgsUnstable.wofi
    pkgs.gammastep
  ];

  x_packages = [
    pkgsUnstable.feh
    pkgs.redshift

  ];

  linux_packages = [
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
    pkgs.discord

    # Note
    pkgsUnstable.obsidian

    ########
    # Util
    ########

    # GUI File manager
    pkgsUnstable.gnome.dconf-editor

    # CLI File manager
    pkgs.ranger
    pkgsUnstable.ueberzugpp
    pkgs.evince
    pkgsUnstable.dunst
    pkgsUnstable.conky
    pkgsUnstable.glxinfo
    pkgsUnstable.hwinfo # System monitoring
    pkgsUnstable.rclone
    pkgsUnstable.rclone-browser
    pkgsUnstable.imagemagick
    
    # Programming
    pkgsUnstable.cargo
    pkgsUnstable.zulu # OpenJDK for Java
    pkgs.texlive.combined.scheme-full

    # Python package
    pkgsUnstable.python311Packages.flake8
    pkgsUnstable.black
    pkgsUnstable.isort
    pkgsUnstable.nodejs_20

    # Music player
    pkgs.spotify

    # Theme
    pkgs.lxappearance

    pkgsUnstable._1password-gui
    pkgsUnstable._1password
  ];

  mac_packages = [ ];
}
