{
  project_root,
  pkgs,
  inputs,
  ...
}: let
  theme-switch = pkgs.writers.writeBashBin "theme-switch" (builtins.readFile "${project_root}/scripts/theme-switch.sh");
  xdg-terminal-exec = pkgs.writers.writeBashBin "xdg-terminal-exec" ''
    #!/bin/sh
    test -n "$*" && args=("$@")
    exec kitty -d "$PWD" -e "''${args[@]}"
  '';
in {
  default_packages = [
    # Utils
    pkgs.bat # A cat clone with syntax highlighting and Git integration
    pkgs.eza # A tiny file explorer
    pkgs.htop # An interactive process viewer
    pkgs.fzf # A command-line fuzzy finder
    pkgs.tree # A recursive directory listing program
    pkgs.tmux # A terminal multiplexer
    pkgs.tmuxinator # A tmux session manager
    pkgs.wget # A command-line tool for retrieving files over HTTP/HTTPS/FTP
    pkgs.jq # A lightweight and flexible command-line JSON processor
    pkgs.ncdu # A disk usage analyzer
    pkgs.zip # A compression and archive utility
    pkgs.unzip # A decompression utility
    pkgs.newsboat # An RSS feed reader
    pkgs.ripgrep
    pkgs.starship
    pkgs.nix-output-monitor
    pkgs.neovim
    pkgs.vscode
  ];

  linux_packages = [
    theme-switch
    xdg-terminal-exec
    inputs.zen-browser.packages."${pkgs.system}".default
    pkgs.prismlauncher
    pkgs.glib
    pkgs.caprine
    pkgs.trash-cli

    # Hyprland
    pkgs.waybar # A Wayland bar for Sway and Hyprland
    pkgs.bun # to run ags
    pkgs.hyprpaper # A wallpaper utility for Hyprland
    pkgs.wl-clipboard # A command-line copy/paste tool for Wayland
    pkgs.slurp # A tool to select a region on a screen
    pkgs.grim # A screen capture utility for Wayland
    pkgs.cliphist # A clipboard manager utility
    inputs.pyprland.packages.${pkgs.system}.pyprland # pyprland
    pkgs.hyprpicker # A launcher/menu program for Hyprland
    pkgs.tofi # A launcher/menu program for Wayland
    pkgs.wev # An event daemon for Wayland
    inputs.hyprland-contrib.packages.${pkgs.system}.hyprprop # Hyprland contrib package for hyprprop
    (pkgs.espanso.override {
      x11Support = false;
      waylandSupport = true;
    })

    # System
    pkgs.inotify-tools # A set of command-line utilities for monitoring file system events
    pkgs.libnotify # A library for sending desktop notifications
    pkgs.ddcutil # A monitor control tool
    pkgs.quickemu # A quick emu launcher

    # Shell
    pkgs.obs-studio # A free and open-source video recording and live streaming software
    pkgs.lazygit # A simple terminal UI for git commands
    pkgs.git-lfs
    pkgs.pamixer # A CLI mixer for PulseAudio
    pkgs.arandr # A UI for managing displays
    pkgs.vlc # A multimedia player

    # Text editor
    pkgs.onlyoffice-bin # An office suite
    pkgs.pdfgrep # A tool to search text in PDF files

    pkgs.adw-gtk3

    # Browser
    # This is an example of overriding chrome start command
    # (pkgs.google-chrome.override {
    #   commandLineArgs = "--ozone-platform-hint=auto --enable-wayland-ime --wayland-text-input-version3";
    # })
    # pkgs.google-chrome

    # Font
    pkgs.liberation_ttf # Liberation TrueType fonts
    pkgs.cantarell-fonts # Cantarell fonts
    pkgs.noto-fonts-color-emoji # Noto Color Emoji fonts
    pkgs.iosevka # Iosevka monospace fonts
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd
    inputs.apple-fonts.packages.${pkgs.system}.ny-nerd

    # Messaging
    pkgs.signal-desktop # Signal Desktop messaging app
    pkgs.discord # Discord messaging app
    pkgs.slack # A messaging and collaboration platform

    # Note
    pkgs.obsidian # A knowledge base and note-taking app

    ######## # Util ########
    # GUI File manager
    pkgs.dconf-editor # GNOME's dconf editor
    pkgs.djvulibre

    # CLI File manager
    pkgs.ueberzugpp # A command-line UI library for image previews
    pkgs.evince # A document viewer
    pkgs.hwinfo # A hardware information tool
    pkgs.imagemagick # A suite of image manipulation tools
  ];

  mac_packages = [
  ];
}
