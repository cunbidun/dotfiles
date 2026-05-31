{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

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
in rec {
  default_packages = [
    # Core CLI utilities
    pkgs.alejandra # Nix formatter
    pkgs.htop # Interactive process viewer
    pkgs.jq # JSON processor
    pkgs.ncdu # Disk usage analyzer
    pkgs.ngrok
    pkgs.nix-output-monitor
    pkgs.pre-commit
    pkgs.pdfgrep
    pkgs.ripgrep
    pkgs.starship
    pkgs.tmux # Terminal multiplexer
    pkgs.tree # Recursive directory listing
    pkgs.unzip
    pkgs.wget
    pkgs.yt-dlp
    pkgs.zip
    pkgs.gh # GitHub CLI
    pkgs.git-lfs
    pkgs.lazygit
    pkgs.newsboat

    # AI and development tooling
    inputs.llm-agents.packages.${system}.codex
    inputs.llm-agents.packages.${system}.opencode
    inputs.llm-agents.packages.${system}.claude-code

    # Shared fonts between Linux and Mac
    inputs.apple-fonts.packages.${system}.ny-nerd
    inputs.apple-fonts.packages.${system}.sf-mono-nerd
    inputs.apple-fonts.packages.${system}.sf-pro-nerd
  ];

  linux_packages = let
    theme-switch = pkgs.writeShellApplication {
      name = "theme-switch";
      text = builtins.readFile ../../scripts/theme-switch.sh;
      runtimeInputs = [
        pkgs.darkman
        pkgs.gawk
        pkgs.gnugrep
        pkgs.systemdMinimal
        pkgs.theme-manager
      ];
    };
  in [
    # Local wrappers and scripts
    theme-switch
    xdg-terminal-exec
    yazi-wrapper

    # AI desktop apps
    inputs.claude-desktop.packages.${system}.claude-desktop-fhs
    inputs.codex-desktop-linux.packages.${system}.codex-desktop

    # Hyprland
    inputs.hyprland-contrib.packages.${system}.hyprprop
    inputs.pyprland.packages.${system}.pyprland
    pkgs.cliphist # Clipboard manager for Wayland
    (pkgs.espanso.override {
      x11Support = false;
      waylandSupport = true;
    })
    pkgs.grim # Wayland screenshot utility
    pkgs.hyprpicker
    pkgs.slurp # Region selector for Wayland screenshots
    pkgs.wev # Wayland event viewer
    pkgs.wl-clipboard # Wayland clipboard tools

    # Desktop and media apps
    pkgs.arandr # Display management UI
    pkgs.blender # 3D modeling and animation
    pkgs.discord
    pkgs.eog
    pkgs.evince
    pkgs.obs-studio
    pkgs.obsidian
    pkgs.signal-desktop
    pkgs.slack
    pkgs.spotify
    pkgs.vlc

    # Development and tooling
    pkgs.adw-gtk3
    pkgs.dconf-editor
    pkgs.dig
    pkgs.djvulibre
    pkgs.glib
    pkgs.hwinfo
    pkgs.imagemagick
    pkgs.inetutils
    pkgs.inotify-tools
    pkgs.libnotify
    pkgs.pamixer
    pkgs.trash-cli
    pkgs.ueberzugpp

    # Fonts
    pkgs.nixpkgs-stable.cantarell-fonts
    pkgs.nixpkgs-stable.iosevka
    pkgs.nixpkgs-stable.liberation_ttf # Stable to avoid frequent repatching
    pkgs.nixpkgs-stable.noto-fonts-cjk-sans
    pkgs.nixpkgs-stable.noto-fonts-cjk-serif
    pkgs.noto-fonts-color-emoji
    pkgs.nixpkgs-stable.wqy_zenhei

    # Stable-pinned apps
    pkgs.nixpkgs-stable.jetbrains.datagrip
    pkgs.nixpkgs-stable.libreoffice
    pkgs.nixpkgs-stable.redisinsight
    pkgs.nixpkgs-stable.zoom-us
  ];

  mac_packages = [];
}
