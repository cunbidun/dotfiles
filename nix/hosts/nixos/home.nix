{
  lib,
  config,
  pkgs,
  inputs,
  userdata,
  ...
}: let
  package_config = import ../../home-manager/packages.nix {
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
    inputs.self.homeManagerModules.theme-manager
    inputs.sops-nix.homeManagerModules.sops
    inputs.opnix.homeManagerModules.default
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/kitty.nix
    ../../home-manager/configs/hyprland/hyprland.nix
    ../../home-manager/configs/hyprpanel.nix
    ../../home-manager/configs/hyprland/hypridle.nix
    ../../home-manager/configs/hyprland/pyprland.nix
    ../../home-manager/configs/hyprland/hyprpaper.nix
    ../../home-manager/configs/nvchad.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/yazi.nix
    ../../home-manager/configs/hyprlock.nix
    ../../home-manager/configs/vicinae.nix
    ../../home-manager/configs/vscode.nix
    inputs.vicinae.homeManagerModules.default
    ../../home-manager/systemd.nix
    ../../home-manager/configs/stylix.nix
    ../../home-manager/configs/activitywatch.nix
    ../../home-manager/configs/chromium.nix
    ../../home-manager/configs/shared/git.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";

  home.packages = package_config.default_packages ++ package_config.linux_packages;

  services.xremap = {
    withWlroots = true;
    watch = true;
    enable = true;
    yamlConfig = ''
      modmap:
        - name: Global
          application:
          remap:
            ALT_L: SUPER_L

        - name: Almost
          application:
            not: [kitty, steam, cs2, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code, code-insiders, blender]
          remap:
            SUPER_L: CONTROL_L

        - name: Other
          application:
            only: [kitty, steam, cs2, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code, code-insiders, blender]
          remap:
            SUPER_L: ALT_L
    '';
  };
  services.gammastep = {
    enable = true;
    provider = "geoclue2";
    temperature = {
      day = 6000;
    };
  };

  # +--------------------+
  # |    Linux Config    |
  # +--------------------+
  fonts.fontconfig = {
    enable = true;
    # Ensure CJK fallback so Chinese glyphs render in terminals/editors.
    defaultFonts = {
      sansSerif = [
        "SFProDisplay Nerd Font"
        "Noto Sans CJK SC"
      ];
      serif = [
        "NewYork Nerd Font"
        "Noto Serif CJK SC"
      ];
      monospace = [
        "SFMono Nerd Font"
        "Noto Sans Mono CJK SC"
      ];
      emoji = ["Noto Color Emoji"];
    };
  };

  home.file = {
    ".config/tmuxinator".source = ../../../utilities/tmuxinator;
  };


  qt = {enable = true;};

  gtk = {
    enable = true;
    gtk3 = {
      bookmarks = [
        "file:///home/${userdata.username}/Downloads"
        "file:///home/${userdata.username}/competitive_programming/output"
        "file:///home/${userdata.username}/Vi"
      ];
    };
    iconTheme = {
      package = pkgs.papirus-nord;
      name = "Papirus-Dark";
    };
  };

  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "image/jpeg" = ["feh.desktop"];
        "image/png" = ["feh.desktop"];
        "text/plain" = ["nvim.desktop"];
        "inode/directory" = ["yazi.desktop"];
        "text/html" = ["google-chrome.desktop"];
        "application/xhtml+xml" = ["google-chrome.desktop"];
        "application/x-www-form-urlencoded" = ["google-chrome.desktop"];
        "x-scheme-handler/http" = ["google-chrome.desktop"];
        "x-scheme-handler/https" = ["google-chrome.desktop"];
        # Point terminal handler at kitty -e; avoids Vicinae sending apps through kitty +open URL mode
        "x-scheme-handler/terminal" = ["kitty.desktop"];
      };
    };

    systemDirs.data = [
      "$HOME/.local/share"
      "/usr/local/share"
      "/usr/share"
      "${pkgs.glib.out}/share/gsettings-schemas"
      "${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}"
    ];
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-termfilechooser
        pkgs.xdg-desktop-portal-gtk
      ];
    };
    portal.config = {
      common.default = ["hyprland;gtk"];
      hyprland.default = ["hyprland"];
      hyprland."org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
      common."org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };

    # https://github.com/hunkyburrito/xdg-desktop-portal-termfilechooser
    # Make sure to Set widget.use-xdg-desktop-portal.file-picker to 1
    configFile = {
      "xdg-desktop-portal-termfilechooser/config" = {
        force = true;
        text = ''
          [filechooser]
          cmd=/etc/profiles/per-user/${userdata.username}/bin/yazi-wrapper
          env=TERMCMD=${pkgs.kitty}/bin/kitty --title FileChooser
        '';
      };

      "uwsm/env" = {
        text = ''
          #!/usr/bin/env bash
          export TERMINAL=kitty
          export QT_QTA_PLATFORMTHEME=qt5ct
          export EDITOR=nvim
          export NIXOS_OZONE_WL=1
        '';
      };
    };
  };

  i18n.inputMethod = {
    enable = true; # also enable auto start
    type = "fcitx5"; # tell HM which backend you want
    fcitx5 = {
      waylandFrontend = true; # flip to false on pure‑X11
      addons = with pkgs; [fcitx5-bamboo]; # pull the Bamboo engine

      settings = {
        ## 1.  ~/.config/fcitx5/profile  ── engine list & order
        inputMethod = {
          "GroupOrder"."0" = "Default";

          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us"; # physical keyboard
            DefaultIM = "keyboard-us";
          };

          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "bamboo";
        };

        ## 2.  ~/.config/fcitx5/config  ── optional global tweaks
        globalOptions = {
          Hotkey = {
            # Enumerate when press trigger key repeatedly
            EnumerateWithTriggerKeys = "True";
            # Skip first input method while enumerating
            EnumerateSkipFirst = "False";
          };
          "Hotkey/TriggerKeys" = {};
          "Hotkey/EnumerateForwardKeys" = {
            "0" = "Super+space";
          };
          "Hotkey/TogglePreedit" = {
            "0" = "Control+Super+space";
          };
          Behavior.ActiveByDefault = true; # start IM on login
        };
      };
    };
  };
  systemd.user.services.fcitx5-daemon = lib.mkForce {};

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.bat = {
    enable = true;
  };
  programs.hyprcursor-phinger.enable = true;
  programs.atuin.enable = true;
  programs.zoxide.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}
