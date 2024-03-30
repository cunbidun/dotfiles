{ pkgs, nixGLWrap, inputs, ... }: {
  linux_packages = [
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
    pkgs.nixpkgs-fmt
    pkgs.syncthing

    # For vim
    pkgs.lunarvim
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.slack

    # Hyprland
    pkgs.waybar
    pkgs.hyprpaper
    pkgs.wofi
    pkgs.gammastep
    pkgs.wl-clipboard
    pkgs.slurp
    pkgs.grim
    pkgs.cliphist
    pkgs.pyprland
    pkgs.hyprpicker
    # pkgs.espanso-wayland # wayland version
    pkgs.tofi
    pkgs.sway-audio-idle-inhibit
    pkgs.eww
    pkgs.wev
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop

    # System
    pkgs.inotify-tools
    pkgs.libnotify
    pkgs.ddcutil
    pkgs.bluetuith

    pkgs.caprine-bin
    pkgs.quickemu

    # shell
    pkgs.obs-studio

    pkgs.lazygit
    pkgs.pulsemixer
    pkgs.pamixer
    pkgs.arandr
    pkgs.vlc
    pkgs.calcurse

    # Text editor
    pkgs.onlyoffice-bin
    pkgs.vscode
    pkgs.pdfgrep

    # Broswer
    pkgs.google-chrome

    # Font
    pkgs.liberation_ttf
    pkgs.cantarell-fonts
    pkgs.noto-fonts-color-emoji
    pkgs.iosevka
    pkgs.nerdfonts
    pkgs.prismlauncher

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
    pkgs.gnome.nautilus
    pkgs.gnome.sushi
    pkgs.gnome.file-roller
    pkgs.gnome3.gvfs

    # CLI File manager
    pkgs.ranger
    pkgs.ueberzugpp
    pkgs.evince
    pkgs.dunst
    pkgs.conky
    pkgs.hwinfo
    pkgs.rclone
    pkgs.rclone-browser
    pkgs.imagemagick
    pkgs.bfg-repo-cleaner

    # Programming
    pkgs.cargo
    pkgs.rustc
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
  ];

  mac_packages = [ ];
}
