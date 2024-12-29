{
  lib,
  config,
  pkgs,
  project_root,
  inputs,
  ...
}: let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.ags.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/alacritty.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprland/waybar.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hypridle.nix"
    "${project_root}/nix/home-manager/configs/hyprland/pyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprpaper.nix"
    "${project_root}/nix/home-manager/configs/fzf.nix"
    "${project_root}/nix/home-manager/configs/nixvim.nix"
    "${project_root}/nix/home-manager/configs/mako.nix"
    "${project_root}/nix/home-manager/configs/tofi.nix"
    "${project_root}/nix/home-manager/configs/vscode.nix"
    "${project_root}/nix/home-manager/configs/swaylock.nix"
    "${project_root}/nix/home-manager/systemd.nix"
    "${project_root}/nix/home-manager/configs/stylix.nix"
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
    inputs.stylix.homeManagerModules.stylix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";

  home.packages = package_config.default_packages ++ package_config.linux_packages;

  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
    ];
  };

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
            not: [Alacritty, steam, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64]
          remap:
            SUPER_L: CONTROL_L

        - name: Other
          application:
            only: [Alacritty, steam, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64]
          remap:
            SUPER_L: ALT_L
    '';
  };
  services.gammastep = {
    enable = true;
    latitude = 40.730610;
    longitude = -73.935242;
    temperature = {
      day = 6000;
    };
  };

  # +--------------------+
  # |    Linux Config    |
  # +--------------------+
  fonts.fontconfig.enable = true;

  home.file = {
    # ".local/bin/hyprland_wrapped".source = "${project_root}/window_manager/hyprland/linux/hyprland_wrapped";
    #
    # ".local/bin/colors-name.txt".source = "${project_root}/local/linux/.local/bin/colors-name.txt";
    # ".local/bin/dotfiles.txt".source = "${project_root}/local/linux/.local/bin/dotfiles.txt";
    # ".local/bin/dotfiles_picker".source = "${project_root}/local/linux/.local/bin/dotfiles_picker";
    # ".local/bin/nord_color_picker".source = "${project_root}/local/linux/.local/bin/nord_color_picker";

    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";

    # Custom deskop files
    ".local/share/applications/uxplay.desktop".source = "${project_root}/utilities/desktops/uxplay.desktop";
    ".config/tmuxinator".source = "${project_root}/utilities/tmuxinator";
    ".tmux.conf".source = "${project_root}/utilities/tmux/.tmux.conf";
  };

  qt = {enable = true;};

  gtk = {
    enable = true;
    gtk3 = {
      bookmarks = [
        "file:///home/cunbidun/Downloads"
        "file:///home/cunbidun/competitive_programming/output"
        "file:///home/cunbidun/Books"
        "file:///home/cunbidun/Vi"
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
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "image/jpeg" = ["feh.desktop"];
        "image/png" = ["feh.desktop"];
        "text/plain" = ["nvim.desktop"];
        "inode/directory" = ["org.gnome.nautilus.desktop"];
      };
    };
    systemDirs.data = [
      "$HOME/.local/share"
      "/usr/local/share"
      "/usr/share"
      "/var/lib/flatpak/exports/share"
      "$HOME/.local/share/flatpak/exports/share"
      "${pkgs.glib.out}/share/gsettings-schemas"
      "${pkgs.gsettings-desktop-schemas}/share"
    ];
  };
  # Add content to .profile
  home.file.".profile".text = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

    UWSM_FINALIZE_VARNAMES="$UWSM_FINALIZE_VARNAMES NIX_LD NIX_LD_LIBRARY_PATH NIXOS_OZONE_WL"
    UWSM_FINALIZE_VARNAMES="$UWSM_FINALIZE_VARNAMES GLFW_IM_MODULE XMODIFIERS GTK_IM_MODULE QT_IM_MODULE"
    UWSM_FINALIZE_VARNAMES="$UWSM_FINALIZE_VARNAMES GIO_EXTRA_MODULES QT_QTA_PLATFORMTHEME"
    UWSM_FINALIZE_VARNAMES="$UWSM_FINALIZE_VARNAMES XDG_DATA_DIRS XDG_CURRENT_DESKTOP"
    UWSM_FINALIZE_VARNAMES="$UWSM_FINALIZE_VARNAMES HOME TERMINAL PICKER EDITOR"

    UWSM_WAIT_VARNAMES="$UWSM_FINALIZE_VARNAMES"
  '';
  home.sessionVariables = {
    PICKER = "tofi";
    TERMINAL = "alacritty";
    QT_QTA_PLATFORMTHEME = "qt5ct";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [fcitx5-unikey fcitx5-gtk];
  };
  systemd.user.services.fcitx5-daemon = lib.mkForce {};

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
  programs.bat = {
    enable = true;
  };
  programs.hyprcursor-phinger.enable = true;
  programs.zoxide.enable = true;

  home.activation = {
    restartAGS = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD /run/current-system/sw/bin/systemctl --user restart ags.service
    '';
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
