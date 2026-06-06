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
    ../../home-manager/profiles/linux.nix
    inputs.sops-nix.homeManagerModules.sops
    inputs.xremap-flake.homeManagerModules.default
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
    inputs.self.homeManagerModules.theme-manager
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/kitty.nix
    ../../home-manager/configs/hyprland/hyprland.nix
    ../../home-manager/configs/hyprpanel.nix
    ../../home-manager/configs/hyprland/hypridle.nix
    ../../home-manager/configs/hyprland/pyprland.nix
    ../../home-manager/configs/hyprland/hyprpaper.nix
    ../../home-manager/configs/nvim.nix
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
    ../../home-manager/configs/minecraft.nix
    ../../home-manager/configs/xremap.nix
    ../../home-manager/configs/taskwarrior.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/hyprsunset.nix
    ../../home-manager/configs/llm_agent.nix
  ];

  home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

  home.packages = package_config.default_packages ++ package_config.linux_packages;

  # Ensure old user-enabled tray applet and gammastep service don't keep autostarting.
  home.activation.disableGammastepIndicator = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run systemctl --user disable --now gammastep.service >/dev/null 2>&1 || true
    run systemctl --user disable --now gammastep-indicator.service >/dev/null 2>&1 || true
  '';

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

  qt = {
    enable = true;
  };

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
    desktopEntries.claude-desktop = {
      name = "Claude";
      genericName = "Claude Desktop";
      comment = "Claude Desktop (Wayland)";
      exec = "env CLAUDE_USE_WAYLAND=1 claude-desktop %u";
      terminal = false;
      icon = "claude-desktop";
      categories = [
        "Office"
        "Utility"
      ];
      mimeType = ["x-scheme-handler/claude"];
      settings = {
        StartupWMClass = "Claude";
      };
    };

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
          export XCURSOR_THEME=phinger-cursors-dark
          export XCURSOR_SIZE=24
        '';
      };

      "uwsm/env-hyprland" = {
        text = ''
          #!/usr/bin/env bash
          export HYPRCURSOR_THEME=hyprcursor-phinger
          export HYPRCURSOR_SIZE=24
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
          Behavior.ActiveByDefault = false; # keep keyboard-us active unless explicitly toggled
        };
      };
    };
  };
  systemd.user.services.fcitx5-daemon = lib.mkForce {};

  programs.bat = {
    enable = true;
  };
  programs.hyprcursor-phinger.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ServerAliveInterval = 20;
        ServerAliveCountMax = 3;
        TCPKeepAlive = "yes";
        IdentityAgent = "~/.1password/agent.sock";
      };
      # Named host entries are discovered by many tunnel UIs.
      "home-server" = {
        HostName = "home-server.${userdata.tailnetDomain}";
        User = userdata.username;
        Port = 22;
      };
    };
  };
  programs.zoxide.enable = true;

  sops = {
    defaultSopsFile = ../../../secrets/user.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
    secrets.github_read_only_token = {
      path = "${config.home.homeDirectory}/.config/opencode/github_read_only_token";
    };
    secrets.ninerouter_api_key = {
      path = "${config.home.homeDirectory}/.config/opencode/ninerouter_api_key";
    };
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
