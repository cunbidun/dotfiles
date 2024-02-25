{ pkgs, config, lib, project_root, inputs, ... }:

let
  # mkDerivation signature: https://blog.ielliott.io/nix-docs/mkDerivation.html
  # {
  #   # Core Attributes
  #   name: 	string
  #   pname?: 	string
  #   version?: 	string
  #   src: 	path
  #   # Building
  #   buildInputs?: 	list[derivation]
  #   buildPhase?: 	string
  #   installPhase?: 	string
  #   builder?: 	path
  #   # Nix shell
  #   shellHook?: 	string
  # }

  # runCommand implementation:
  #  runCommand' = stdenv: name: env: buildCommand: 
  #      stdenv.mkDerivation ({ 
  #        inherit name buildCommand; 
  #        passAsFile = [ "buildCommand" ]; 
  #      } // env); 
  nixGLWrap = pkg:
    pkgs.stdenv.mkDerivation ({
      pname = "${pkg.name}-nixgl-wrapper";
      version = "${pkg.version}";
      buildCommand = ''
        mkdir $out
        ln -s ${pkg}/* $out
        rm $out/bin
        mkdir $out/bin
        for bin in ${pkg}/bin/*; do
         wrapped_bin=$out/bin/$(basename $bin)
         echo "exec ${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL $bin  \"\$@\"" > $wrapped_bin
         chmod +x $wrapped_bin
        done
      '';
      passAsFile = [ "buildCommand" ];
    } // { });

  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    nixGLWrap = nixGLWrap;
    inputs = inputs;
  };
  systemd_config = import "${project_root}/nix/home-manager/systemd.nix" {
    pkgs = pkgs;
    lib = lib;
    project_root = project_root;
  };
  # color-scheme = import "${project_root}/nix/home-manager/colors/vscode-dark.nix";
  color-scheme = import "${project_root}/nix/home-manager/colors/nord.nix";
  swaylock-settings =
    import "${project_root}/nix/home-manager/configs/swaylock.nix" { color-scheme = color-scheme; };
  alacritty-settings =
    import "${project_root}/nix/home-manager/configs/alacritty.nix" { color-scheme = color-scheme; };
  hyprland_configs = import "${project_root}/nix/home-manager/configs/hyprland/configs.nix" { pkgs = pkgs; color-scheme = color-scheme; };
in
{
  imports = [
    inputs.xremap-flake.homeManagerModules.default
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";

  home.packages = package_config.default_packages ++ package_config.linux_packages
    ++ package_config.x_packages ++ package_config.wayland_packages;

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

  home.file =
    {
      ".local/bin/hyprland_wrapped".source =
        "${project_root}/window_manager/hyprland/linux/hyprland_wrapped";
      ".config/waybar/".source =
        "${project_root}/window_manager/hyprland/linux/.config/waybar";
      ".config/hypr/pyprland.toml".source =
        "${project_root}/window_manager/hyprland/linux/.config/hypr/pyprland.toml";
      ".config/hypr/hyprpaper.conf".source =
        "${project_root}/window_manager/hyprland/linux/.config/hypr/hyprpaper.conf";
      ".config/tofi/config".source =
        "${project_root}/utilities/tofi/linux/.config/tofi/config";
      ".config/dunst/dunstrc".source = "${project_root}/utilities/dunst/dunstrc";
      ".config/tmuxinator".source = "${project_root}/utilities/tmuxinator";
      ".tmux.conf".source = "${project_root}/utilities/tmux/.tmux.conf";

      #######################
      # lvim configurations #
      #######################
      ".config/lvim/lua".source = "${project_root}/text_editor/lvim/lua";
      ".config/lvim/snippet".source = "${project_root}/text_editor/lvim/snippet";
      ".config/lvim/config.lua".source =
        "${project_root}/text_editor/lvim/config.lua";
      ".config/lvim/cp.vim".source = "${project_root}/text_editor/lvim/cp.vim";
      ".config/lvim/markdown-preview.vim".source =
        "${project_root}/text_editor/lvim/markdown-preview.vim";

      ".config/ranger/commands_full.py".source =
        "${project_root}/utilities/ranger/commands_full.py";
      ".config/ranger/commands.py".source =
        "${project_root}/utilities/ranger/commands.py";
      ".config/ranger/rc.conf".source = "${project_root}/utilities/ranger/rc.conf";
      ".config/ranger/rifle.conf".source =
        "${project_root}/utilities/ranger/rifle.conf";
      ".config/ranger/scope.sh".source = "${project_root}/utilities/ranger/scope.sh";

      # ".themes".source = config.lib.file.mkOutOfStoreSymlink
      #   "${config.home.homeDirectory}/.nix-profile/share/themes";
      # ".icons".source = config.lib.file.mkOutOfStoreSymlink
      #   "${config.home.homeDirectory}/.nix-profile/share/icons";
      # ".fonts".source = config.lib.file.mkOutOfStoreSymlink
      #   "${config.home.homeDirectory}/.nix-profile/share/fonts";
      ".config/swaylock/config".text = swaylock-settings.settings;

      ".local/bin/colors-name.txt".source =
        "${project_root}/local/linux/.local/bin/colors-name.txt";
      ".local/bin/decrease_volume".source =
        "${project_root}/local/linux/.local/bin/decrease_volume";
      ".local/bin/dotfiles.txt".source =
        "${project_root}/local/linux/.local/bin/dotfiles.txt";
      ".local/bin/dotfiles_picker".source =
        "${project_root}/local/linux/.local/bin/dotfiles_picker";
      ".local/bin/increase_volume".source =
        "${project_root}/local/linux/.local/bin/increase_volume";
      ".local/bin/nord_color_picker".source =
        "${project_root}/local/linux/.local/bin/nord_color_picker";
      ".local/bin/sc_brightness_change".source =
        "${project_root}/local/linux/.local/bin/sc_brightness_change";
      ".local/bin/sc_get_brightness_percentage".source =
        "${project_root}/local/linux/.local/bin/sc_get_brightness_percentage";
      ".local/bin/sc_hyprland_count_minimized.py".source =
        "${project_root}/local/linux/.local/bin/sc_hyprland_count_minimized.py";
      ".local/bin/sc_hyprland_minimize".source =
        "${project_root}/local/linux/.local/bin/sc_hyprland_minimize";
      ".local/bin/sc_hyprland_show_minimize".source =
        "${project_root}/local/linux/.local/bin/sc_hyprland_show_minimize";
      ".local/bin/sc_window_picker".source =
        "${project_root}/local/linux/.local/bin/sc_window_picker";
      ".local/bin/toggle_volume".source =
        "${project_root}/local/linux/.local/bin/toggle_volume";
      ".local/bin/sc_prompt".source =
        "${project_root}/local/linux/.local/bin/sc_prompt";
      ".local/bin/sc_weather".source =
        "${project_root}/local/linux/.local/bin/sc_weather";
    };

  dconf =
    {
      enable = true;
      settings = {
        # "org/nemo/preferences" = {
        #   show-hidden-files = true;
        # };
        # "org/cinnamon/desktop/default-applications/terminal" = {
        #   exec = "alacritty";
        #   exec-arg = "-e";
        # };
        "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
      };
    };

  qt = {
    enable = true;
    platformTheme = "qtct";
    style = { name = "adwaita-dark"; };
  };

  # home.pointerCursor = {
  #   gtk.enable = true;
  #   # x11.enable = true;
  #   package = pkgs.apple-cursor;
  #   name = "macOS-Monterey";
  #   size = 24;
  # };

  gtk =
    {
      enable = true;
      gtk3 = {
        extraConfig = {
          gtk-font-name = "Cantarell 11";
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-xft-rgba = "none";
        };
        bookmarks = [
          "file:///home/cunbidun/Downloads"
          "file:///home/cunbidun/competitive_programming/output"
        ];
      };
      gtk4 = {
        extraConfig = {
          gtk-font-name = "Cantarell 11";
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-xft-rgba = "none";
        };
      };
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome.gnome-themes-extra;
      };
      cursorTheme = {
        package = pkgs.apple-cursor;
        name = "macOS-Monterey";
        size = 24;
      };
      iconTheme = {
        package = pkgs.papirus-nord;
        name = "Papirus-Dark";
      };
    };

  xdg.mimeApps =
    {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "image/jpeg" = [ "feh.desktop" ];
        "image/png" = [ "feh.desktop" ];
        "text/plain" = [ "lvim.desktop" ];
        "inode/directory" = [ "org.gnome.nautilus.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      };
    };

  systemd.user = systemd_config;
  home.sessionVariables =
    {
      # Setting this is to local the .desktop files
      XDG_DATA_DIRS =
        "$HOME/.local/share:/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS";
      PICKER = "tofi";
      TERMINAL = "alacritty";
      GTK_THEME = "Adwaita-dark";
      QT_QTA_PLATFORMTHEME = "qt5ct";
      GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules";
    };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-unikey fcitx5-gtk ];
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      cdnote = "cd $HOME/note";
      s = "source $HOME/.zshrc";
      CP = "$HOME/competitive_programming/";
      r = "ranger";
      ls = "exa -la";
      cat = "bat";
      tree = "tree -a";

      # vim;
      vi = "lvim";
      nvim = "lvim";
      vim = "lvim";
    };
    initExtra = ''
      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim
      . $HOME/dotfiles/zsh/zshpath
      . $HOME/dotfiles/zsh/zshtheme
      export BAT_STYLE="plain"
      export BAT_THEME="${color-scheme.bat_theme}"
      export BAT_OPTS="--color always"
      export FZF_DEFAULT_OPTS="${color-scheme.fzf_default_opts}"
    '';
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = alacritty-settings.settings;
  };
  wayland.windowManager.hyprland = hyprland_configs.settings;
  programs.firefox = {
    enable = true;
  };
}
