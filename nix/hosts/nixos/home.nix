{
  lib,
  config,
  pkgs,
  project_root,
  inputs,
  userdata,
  ...
}: let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    project_root = project_root;
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
    inputs.stylix.homeModules.stylix
    inputs.self.homeManagerModules.theme-manager
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/kitty.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprpanel.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hypridle.nix"
    "${project_root}/nix/home-manager/configs/hyprland/pyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprpaper.nix"
    "${project_root}/nix/home-manager/configs/firefox.nix"
    "${project_root}/nix/home-manager/configs/nvim.nix"
    "${project_root}/nix/home-manager/configs/tmux.nix"
    "${project_root}/nix/home-manager/configs/tofi.nix"
    "${project_root}/nix/home-manager/configs/yazi.nix"
    "${project_root}/nix/home-manager/configs/hyprlock.nix"
    "${project_root}/nix/home-manager/configs/vscode"
    inputs.vicinae.homeManagerModules.default
    "${project_root}/nix/home-manager/configs/winapps"
    "${project_root}/nix/home-manager/systemd.nix"
    "${project_root}/nix/home-manager/configs/stylix.nix"
    "${project_root}/nix/home-manager/configs/activitywatch.nix"
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";

  home.packages = package_config.default_packages ++ package_config.linux_packages;

  services.xremap = {
    withWlroots = true;
    watch = true;
    yamlConfig = ''
      modmap:
        - name: Global
          application:
          remap:
            ALT_L: SUPER_L

        - name: Almost
          application:
            not: [kitty, steam, cs2, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code, blender]
          remap:
            SUPER_L: CONTROL_L

        - name: Other
          application:
            only: [kitty, steam, cs2, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code, blender]
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
  fonts.fontconfig.enable = true;

  home.file = {
    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";

    # TODO: Not hermetic, relying on dotfiles install at dotfiles
    # ".config/Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/settings.json";
    # ".config/Code/User/keybindings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/keybindings.json";
    ".config/nvim".source =
      if userdata.hermeticNvimConfig
      then "${project_root}/utilities/nvim"
      else config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim";

    # Custom desktop files
    ".local/share/applications/uxplay.desktop".source = "${project_root}/utilities/desktops/uxplay.desktop";

    ".config/tmuxinator".source = "${project_root}/utilities/tmuxinator";
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
      };
    };

    systemDirs.data = [
      "$HOME/.local/share"
      "/usr/local/share"
      "/usr/share"
      "${pkgs.glib.out}/share/gsettings-schemas"
      "${pkgs.gsettings-desktop-schemas}/share"
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
          export PICKER=tofi
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
  programs.git = {
    enable = true;
    userName = userdata.name;
    userEmail = userdata.email;
  };
  programs.bat = {
    enable = true;
  };
  programs.hyprcursor-phinger.enable = true;
  programs.zoxide.enable = true;

  services.vicinae = {
    enable = true;
    autoStart = true;
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
}
