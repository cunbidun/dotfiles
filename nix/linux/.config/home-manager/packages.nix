{pkgs, ...}: {
  default_packages = [
    # Utils
    pkgs.bat # cat
    pkgs.eza # ls
    pkgs.htop
    pkgs.fzf
    pkgs.neofetch
    pkgs.tree
    # pkgs.espanso
    pkgs.tmux
    pkgs.tmuxinator
    pkgs.wget
    pkgs.jq
    pkgs.ncdu
    pkgs.zip
    pkgs.unzip
    pkgs.newsboat

    pkgs.nixfmt
    pkgs.bazel

    # For vim
    pkgs.shellcheck
    pkgs.shfmt
  ];

  wayland_packages = [
    # Hyprland
    pkgs.waybar
    pkgs.hyprpaper
    pkgs.wofi
    pkgs.gammastep
    pkgs.wl-clipboard pkgs.slurp pkgs.grim
    pkgs.espanso-wayland
  ];

  x_packages = [
    pkgs.feh
    pkgs.redshift

  ];

  linux_packages = [
    # Text editor
    pkgs.vscode

    # Broswer
    pkgs.google-chrome
    pkgs.firefox

    # Font
    pkgs.liberation_ttf
    pkgs.cantarell-fonts
    pkgs.noto-fonts-color-emoji

    # Games
    pkgs.minecraft

    # Messaging
    pkgs.signal-desktop
    pkgs.discord

    # Note
    pkgs.obsidian

    ########
    # Util
    ########

    # GUI File manager
    pkgs.gnome.dconf-editor

    # CLI File manager
    pkgs.ranger
    pkgs.ueberzugpp
    pkgs.evince
    pkgs.dunst
    pkgs.conky
    pkgs.glxinfo
    pkgs.hwinfo # System monitoring
    pkgs.rclone
    pkgs.rclone-browser
    pkgs.imagemagick
    
    # Programming
    pkgs.cargo
    pkgs.zulu # OpenJDK for Java
    pkgs.texlive.combined.scheme-full

    # Python package
    pkgs.python311Packages.flake8
    pkgs.black
    pkgs.isort
    pkgs.nodejs_20

    # Music player
    pkgs.spotify

    # Theme
    pkgs.lxappearance

    pkgs._1password-gui
    pkgs._1password
  ];

  mac_packages = [ ];
}
