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
    pkgs = pkgs;
    inputs = inputs;
  };
  xdg-terminal-exec = ''
    #!/bin/sh
    test -n "$*" && args=("$@")
    exec kitty -d "$PWD" -e "''${args[@]}"
  '';
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/kitty.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprland/waybar.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hypridle.nix"
    "${project_root}/nix/home-manager/configs/hyprland/pyprland.nix"
    "${project_root}/nix/home-manager/configs/hyprland/hyprpaper.nix"
    "${project_root}/nix/home-manager/configs/fzf.nix"
    "${project_root}/nix/home-manager/configs/nvim.nix"
    "${project_root}/nix/home-manager/configs/mako.nix"
    "${project_root}/nix/home-manager/configs/tmux.nix"
    "${project_root}/nix/home-manager/configs/tofi.nix"
    "${project_root}/nix/home-manager/configs/yazi.nix"
    "${project_root}/nix/home-manager/configs/swaylock.nix"
    "${project_root}/nix/home-manager/systemd.nix"
    "${project_root}/nix/home-manager/configs/stylix.nix"
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
    inputs.stylix.homeManagerModules.stylix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";

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
            not: [kitty, steam, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code]
          remap:
            SUPER_L: CONTROL_L

        - name: Other
          application:
            only: [kitty, steam, dota2, qemu-system-x86_64, qemu, Qemu-system-x86_64, code]
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
    ".local/bin/vscode_extension.py".source = "${project_root}/scripts/vscode_extension.py";
    ".local/bin/xdg-terminal-exec" = {
      text = xdg-terminal-exec;
      executable = true;
    };

    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";

    # TODO: Not hermetic, relying on dotfiles install at dotfiles
    ".config/Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/settings.json";
    ".config/Code/User/keybindings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/keybindings.json";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim";

    # Custom desktop files
    ".local/share/applications/uxplay.desktop".source = "${project_root}/utilities/desktops/uxplay.desktop";
    ".local/share/applications/zen.desktop".source = "${project_root}/utilities/desktops/zen.desktop";

    ".config/tmuxinator".source = "${project_root}/utilities/tmuxinator";
    ".tmux.conf".source = "${project_root}/utilities/tmux/.tmux.conf";
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

        # default bookmarks
        "x-scheme-handler/http" = ["zen.desktop"];
        "x-scheme-handler/https" = ["zen.desktop"];
        "x-scheme-handler/chrome" = ["zen.desktop"];
        "text/html" = ["zen.desktop"];
        "application/x-extension-htm" = ["zen.desktop"];
        "application/x-extension-html" = ["zen.desktop"];
        "application/x-extension-shtml" = ["zen.desktop"];
        "application/xhtml+xml" = ["zen.desktop"];
        "application/x-extension-xhtml" = ["zen.desktop"];
        "application/x-extension-xht" = ["zen.desktop"];
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
    configFile."xdg-desktop-portal-termfilechooser/config" = {
      force = true;
      text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        env=TERMCMD=${pkgs.kitty}/bin/kitty --title FileChooser
      '';
    };
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
    TERMINAL = "kitty";
    QT_QTA_PLATFORMTHEME = "qt5ct";
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [fcitx5-bamboo fcitx5-gtk];
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
