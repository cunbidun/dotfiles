{pkgs, ...}: {
  default_packages = [
    # Utils
    pkgs.bat # cat
    pkgs.eza # ls
    pkgs.htop
    pkgs.fzf
    pkgs.neofetch
    pkgs.tree
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
    pkgs.syncthing

    # For vim
    pkgs.shellcheck
    pkgs.shfmt

    pkgs.caprine-bin
    pkgs.gnome.gnome-terminal
    pkgs.gtk4
    pkgs.gnome.nautilus 
    pkgs.gnome.sushi 
    pkgs.gnome.file-roller
    pkgs.slack
  ];

  wayland_packages = [
    # Hyprland
    pkgs.waybar
    pkgs.hyprpaper
    pkgs.wofi
    pkgs.gammastep
    pkgs.wl-clipboard pkgs.slurp pkgs.grim pkgs.cliphist
    pkgs.pyprland
    pkgs.hyprpicker
    # pkgs.espanso-wayland # wayland version
    pkgs.tofi
    pkgs.sway-audio-idle-inhibit
    pkgs.eww-wayland
    # pkgs.hyprland
    # pkgs.xdg-desktop-portal-hyprland
  ];

  x_packages = [
    pkgs.feh
    pkgs.redshift
    # pkgs.espanso # X version
  ];

  linux_packages = [
    # Text editor
    pkgs.onlyoffice-bin
    pkgs.vscode
    pkgs.pdfgrep

    # Broswer
    pkgs.google-chrome
    pkgs.firefox-wayland

    # Font
    pkgs.liberation_ttf
    pkgs.cantarell-fonts
    pkgs.noto-fonts-color-emoji
    pkgs.iosevka

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
    pkgs.hwinfo # System monitoring
    pkgs.rclone
    pkgs.rclone-browser
    pkgs.imagemagick
    pkgs.bfg-repo-cleaner
    
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
