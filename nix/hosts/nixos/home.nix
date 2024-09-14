{
  pkgs,
  config,
  lib,
  project_root,
  inputs,
  ...
}: let
  color-scheme =
    import "${project_root}/nix/home-manager/colors/vscode-dark.nix";

  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    inputs = inputs;
  };
  systemd_config = import "${project_root}/nix/home-manager/systemd.nix" {
    inputs = inputs;
    pkgs = pkgs;
    lib = lib;
    project_root = project_root;
  };
  swaylock-settings = import "${project_root}/nix/home-manager/configs/swaylock.nix" {
    color-scheme = color-scheme;
  };
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.ags.homeManagerModules.default
    (import "${project_root}/nix/home-manager/configs/zsh.nix" {
      color-scheme = color-scheme;
    })
    (import "${project_root}/nix/home-manager/configs/alacritty.nix" {
      color-scheme = color-scheme;
      pkgs = pkgs;
    })
    (import "${project_root}/nix/home-manager/configs/hyprland/configs.nix" {
      inputs = inputs;
      pkgs = pkgs;
      color-scheme = color-scheme;
      lib = lib;
    })
    (import "${project_root}/nix/home-manager/configs/hyprland/waybar.nix" {
      pkgs = pkgs;
      lib = lib;
      project_root = project_root;
    })
    "${project_root}/nix/home-manager/configs/fzf.nix"
    "${project_root}/nix/home-manager/configs/nixvim.nix"
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";

  home.packages =
    package_config.default_packages
    ++ package_config.linux_packages;

  services.xremap = {
    withWlroots = true;
    watch = true;
    yamlConfig = ''
      modmap:
        - name: Global
          application:
            not: [Alacritty, steam, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64]
          remap:
            Alt_L: Ctrl_L
    '';
  };

  # +--------------------+
  # |    Linux Config    |
  # +--------------------+
  fonts.fontconfig.enable = true;

  home.file = {
    ".local/bin/hyprland_wrapped".source = "${project_root}/window_manager/hyprland/linux/hyprland_wrapped";
    ".config/hypr/pyprland.toml".source = "${project_root}/window_manager/hyprland/linux/.config/hypr/pyprland.toml";
    ".config/hypr/hyprpaper.conf".source = "${project_root}/window_manager/hyprland/linux/.config/hypr/hyprpaper.conf";
    ".config/hypr/hypridle.conf".source = "${project_root}/window_manager/hyprland/linux/.config/hypr/hypridle.conf";
    ".config/tofi/config".source = "${project_root}/utilities/tofi/linux/.config/tofi/config";
    ".config/dunst/dunstrc".source = "${project_root}/utilities/dunst/dunstrc";

    ".config/activitywatch/aw-qt/aw-qt.toml".source = "${project_root}/utilities/aw/aw-qt.toml";

    ".config/swaylock/config".text = swaylock-settings.settings;
    ".local/bin/colors-name.txt".source = "${project_root}/local/linux/.local/bin/colors-name.txt";
    ".local/bin/dotfiles.txt".source = "${project_root}/local/linux/.local/bin/dotfiles.txt";
    ".local/bin/dotfiles_picker".source = "${project_root}/local/linux/.local/bin/dotfiles_picker";
    ".local/bin/nord_color_picker".source = "${project_root}/local/linux/.local/bin/nord_color_picker";
    ".local/bin/sc_brightness_change".source = "${project_root}/local/linux/.local/bin/sc_brightness_change";
    ".local/bin/sc_get_brightness_percentage".source = "${project_root}/local/linux/.local/bin/sc_get_brightness_percentage";
    ".local/bin/sc_hyprland_minimize".source = "${project_root}/local/linux/.local/bin/sc_hyprland_minimize";
    ".local/bin/sc_hyprland_show_minimize".source = "${project_root}/local/linux/.local/bin/sc_hyprland_show_minimize";
    ".local/bin/sc_window_picker".source = "${project_root}/local/linux/.local/bin/sc_window_picker";
    ".local/bin/sc_prompt".source = "${project_root}/local/linux/.local/bin/sc_prompt";
    ".local/bin/sc_weather".source = "${project_root}/local/linux/.local/bin/sc_weather";
    ".local/bin/aw-awatcher".source = "${project_root}/local/linux/.local/bin/aw-awatcher";
    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";

    # Custom deskop files
    ".local/share/applications/uxplay.desktop".source = "${project_root}/utilities/desktops/uxplay.desktop";
    ".config/tmuxinator".source = "${project_root}/utilities/tmuxinator";
    ".tmux.conf".source = "${project_root}/utilities/tmux/.tmux.conf";
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {color-scheme = "prefer-dark";};
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {name = "adwaita-dark";};
  };

  gtk = {
    enable = true;
    gtk3 = {
      extraConfig = {
        gtk-font-name = "SFProDisplay Nerd Font 11";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "none";
      };
      bookmarks = [
        "file:///home/cunbidun/Downloads"
        "file:///home/cunbidun/competitive_programming/output"
        "file:///home/cunbidun/Books"
      ];
    };
    gtk4 = {
      extraConfig = {
        gtk-font-name = "SFProDisplay Nerd Font 11";
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintfull";
        gtk-xft-rgba = "none";
      };
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      package = pkgs.papirus-nord;
      name = "Papirus-Dark";
    };
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";  # Change to your preferred browser's .desktop entry
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = ["org.gnome.Evince.desktop"];
      "image/jpeg" = ["feh.desktop"];
      "image/png" = ["feh.desktop"];
      "text/plain" = ["nvim.desktop"];
      "inode/directory" = ["org.gnome.nautilus.desktop"];
    };
  };

  systemd.user = systemd_config;
  home.sessionVariables = {
    # Setting this is to local the .desktop files
    XDG_DATA_DIRS = "$HOME/.local/share:/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS";
    PICKER = "tofi";
    TERMINAL = "alacritty";
    GTK_THEME = "Adwaita-dark";
    QT_QTA_PLATFORMTHEME = "qt5ct";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
    EDITOR = "nvim";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [fcitx5-unikey fcitx5-gtk];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };
  programs.ags = {
    enable = true;
    # additional packages to add to gjs's runtime
    extraPackages = with pkgs; [gtksourceview webkitgtk accountsservice];
  };
  home.pointerCursor = {
    # https://github.com/phisch/phinger-cursors
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
  };
  programs.hyprcursor-phinger.enable = true;

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
