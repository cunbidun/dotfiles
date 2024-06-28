{
  pkgs,
  inputs,
  ...
}: {
  default_packages = [
    # Utils
    pkgs.bat # A cat clone with syntax highlighting and Git integration
    pkgs.eza # A tiny file explorer
    pkgs.htop # An interactive process viewer
    pkgs.fzf # A command-line fuzzy finder
    pkgs.neofetch # A system information tool
    pkgs.tree # A recursive directory listing program
    pkgs.tmux # A terminal multiplexer
    pkgs.tmuxinator # A tmux session manager
    pkgs.wget # A command-line tool for retrieving files over HTTP/HTTPS/FTP
    pkgs.jq # A lightweight and flexible command-line JSON processor
    pkgs.ncdu # A disk usage analyzer
    pkgs.zip # A compression and archive utility
    pkgs.unzip # A decompression utility
    pkgs.newsboat # An RSS feed reader
    pkgs.syncthing # A continuous file synchronization program
    pkgs.alejandra # nix formatter
    pkgs.shfmt # nix formatter
  ];

  linux_packages = [
    pkgs.nix-output-monitor
    pkgs.devenv
    pkgs.prismlauncher

    # Hyprland
    pkgs.waybar # A Wayland bar for Sway and Hyprland
    pkgs.hyprpaper # A wallpaper utility for Hyprland
    pkgs.gammastep # A screen temperature adjusting utility
    pkgs.wl-clipboard # A command-line copy/paste tool for Wayland
    pkgs.slurp # A tool to select a region on a screen
    pkgs.grim # A screen capture utility for Wayland
    pkgs.cliphist # A clipboard manager utility
    inputs.pyprland.packages.${pkgs.system}.pyprland # pyprland
    pkgs.hyprpicker # A launcher/menu program for Hyprland
    pkgs.tofi # A launcher/menu program for Wayland
    pkgs.wev # An event daemon for Wayland
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop # Hyprland contrib package for hyprprop
    #pkgs.espanso-wayland # Text expander for Wayland (commented out)

    # System
    pkgs.inotify-tools # A set of command-line utilities for monitoring file system events
    pkgs.libnotify # A library for sending desktop notifications
    pkgs.ddcutil # A monitor control tool
    pkgs.quickemu # A quick emu launcher

    # Shell
    pkgs.obs-studio # A free and open-source video recording and live streaming software
    pkgs.lazygit # A simple terminal UI for git commands
    pkgs.pamixer # A CLI mixer for PulseAudio
    pkgs.arandr # A UI for managing displays
    pkgs.vlc # A multimedia player

    # Text editor
    pkgs.onlyoffice-bin # An office suite
    pkgs.vscode # Visual Studio Code
    pkgs.pdfgrep # A tool to search text in PDF files

    # Browser
    (pkgs.google-chrome.override {
      commandLineArgs = "--ozone-platform=wayland";
    })

    # Font
    pkgs.liberation_ttf # Liberation TrueType fonts
    pkgs.cantarell-fonts # Cantarell fonts
    pkgs.noto-fonts-color-emoji # Noto Color Emoji fonts
    pkgs.iosevka # Iosevka monospace fonts
    pkgs.nerdfonts # Iconic font aggregation
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd

    # Messaging
    pkgs.signal-desktop # Signal Desktop messaging app
    pkgs.discord # Discord messaging app
    pkgs.caprine-bin # An unofficial Facebook Messenger app
    pkgs.slack # A messaging and collaboration platform

    # Note
    pkgs.obsidian # A knowledge base and note-taking app
    pkgs.activitywatch

    ######## # Util ########
    # GUI File manager
    pkgs.gnome.dconf-editor # GNOME's dconf editor
    pkgs.gnome.nautilus # GNOME's file manager
    pkgs.gnome.sushi # GNOME's preview utility
    pkgs.gnome.file-roller # GNOME's archive manager
    pkgs.gnome3.gvfs # GNOME's virtual file system
    pkgs.djvulibre

    # CLI File manager
    pkgs.ranger # A console file manager
    pkgs.ueberzugpp # A command-line UI library for image previews
    pkgs.evince # A document viewer
    pkgs.dunst # A lightweight notification daemon
    pkgs.conky # A lightweight system monitor
    pkgs.hwinfo # A hardware information tool
    pkgs.rclone # A command-line tool for cloud storage
    pkgs.rclone-browser # A browser UI for rclone
    pkgs.imagemagick # A suite of image manipulation tools
    pkgs.bfg-repo-cleaner # A tool to remove large or problematic blobs from Git repos

    # Programming
    pkgs.cargo # The Rust package manager
    pkgs.rustc # The Rust compiler
    pkgs.texlive.combined.scheme-full # A comprehensive TeX distribution

    # Python package
    pkgs.python311Packages.flake8 # A Python code style checker
    pkgs.black # A Python code formatter
    pkgs.isort # A Python utility for sorting imports
    pkgs.nodejs_20 # Node.js version 20

    # Music player
    pkgs.spotify # The Spotify music streaming app

    # Theme
    pkgs.lxappearance # A desktop theme switcher
    pkgs.jetbrains-toolbox
  ];

  mac_packages = [
    pkgs.lunarvim
  ];
}
