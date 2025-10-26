{
  pkgs,
  inputs,
  ...
}: let
  yazi-wrapper = pkgs.writeShellApplication {
    name = "yazi-wrapper";
    text = ''
      #!/usr/bin/env sh
      # This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
      #
      # For more information about input/output arguments read `xdg-desktop-portal-termfilechooser(5)`

      set -ex

      multiple="$1"
      directory="$2"
      save="$3"
      path="$4"
      out="$5"

      cmd="yazi"
      termcmd="''${TERMCMD:-kitty --title 'termfilechooser'}"

      if [ "$save" = "1" ]; then
          # save a file
          set -- --chooser-file="$out" "$path"
      elif [ "$directory" = "1" ]; then
          # upload files from a directory
          set -- --chooser-file="$out" --cwd-file="$out" "$path"
      elif [ "$multiple" = "1" ]; then
          # upload multiple files
          set -- --chooser-file="$out" "$path"
      else
          # upload only 1 file
          set -- --chooser-file="$out" "$path"
      fi

      command="$termcmd $cmd"
      for arg in "$@"; do
          # escape double quotes
          escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
          # escape spaces
          command="$command \"$escaped\""
      done

      sh -c "$command"
    '';
  };
  xdg-terminal-exec = pkgs.writers.writeBashBin "xdg-terminal-exec" ''
    #!/bin/sh
    test -n "$*" && args=("$@")
    exec kitty -d "$PWD" -e "''${args[@]}"
  '';
in {
  default_packages = [
    # Utils
    pkgs.htop # An interactive process viewer
    pkgs.tree # A recursive directory listing program
    pkgs.tmux # A terminal multiplexer
    pkgs.tmuxinator # A tmux session manager
    pkgs.wget # A command-line tool for retrieving files over HTTP/HTTPS/FTP
    pkgs.jq # A lightweight and flexible command-line JSON processor
    pkgs.ncdu # A disk usage analyzer
    pkgs.zip # A compression and archive utility
    pkgs.unzip # A decompression utility
    pkgs.ripgrep
    pkgs.starship
    pkgs.nix-output-monitor
    pkgs.alejandra # nix formatter
    pkgs.ngrok

    # AI/Development tools
    inputs.codex-nix.packages.${pkgs.system}.default
  ];

  linux_packages = let
    theme-switch = pkgs.writeShellApplication {
      name = "theme-switch";
      text = builtins.readFile ../../scripts/theme-switch.sh;
      runtimeInputs = [pkgs.gawk pkgs.gnugrep pkgs.systemdMinimal pkgs.darkman pkgs.theme-manager];
    };
  in [
    theme-switch
    yazi-wrapper
    xdg-terminal-exec
    pkgs.blender # A 3D modeling and animation software
    # TODO: Java 8 is not working
    # pkgs.prismlauncher
    pkgs.glib
    pkgs.trash-cli
    pkgs.dig
    pkgs.inetutils
    pkgs.eog

    # Hyprland
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

    # Shell
    pkgs.obs-studio # A free and open-source video recording and live streaming software
    pkgs.lazygit # A simple terminal UI for git commands
    pkgs.git-lfs
    pkgs.pamixer # A CLI mixer for PulseAudio
    pkgs.arandr # A UI for managing displays
    pkgs.vlc # A multimedia player

    # Text editor
    pkgs.pdfgrep # A tool to search text in PDF files

    pkgs.adw-gtk3

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
    pkgs.yt-dlp # A command-line tool to download videos from YouTube and other sites

    pkgs.newsboat # An RSS feed reader
  ];

  mac_packages = [
  ];
}
