{
  inputs,
  pkgs,
  lib,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  themeConfigs = import ./shared/theme-configs.nix;

  enabledExtensions = with spicePkgs.extensions; [
    adblockify
    hidePodcasts
  ];

  mkSpicedSpotify = themeConfig: let
    theme = spicePkgs.themes.${themeConfig.spicetify.theme};
    allExtensions = enabledExtensions ++ (theme.requiredExtensions or []);
    xpui = {
      AdditionalOptions = {
        extensions = lib.concatMapStringsSep "|" (item: item.name) allExtensions;
        custom_apps = "";
        sidebar_config = false;
        home_config = theme.homeConfig or true;
        experimental_features = lib.any (item: item.experimentalFeatures or false) allExtensions;
      };
      Setting = {
        spotify_path = "__SPOTIFY__";
        prefs_path = "__PREFS__";
        inject_theme_js = theme.injectThemeJs or true;
        replace_colors = theme.replaceColors or true;
        check_spicetify_update = false;
        current_theme = theme.name;
        color_scheme = themeConfig.spicetify.colorScheme;
        inject_css = theme.injectCss or true;
        overwrite_assets = theme.overwriteAssets or false;
        spotify_launch_flags = "";
        always_enable_devtools = false;
      };
      Patch = theme.patches or {};
      Preprocesses = {
        disable_ui_logging = true;
        remove_rtl_rule = true;
        expose_apis = true;
        disable_sentry = true;
      };
      Backup = {
        inherit (pkgs.spotify) version;
        "with" = "Dev";
      };
    };
  in
    spicePkgs.spicetifyBuilder {
      spotify = pkgs.spotify;
      spicetify-cli = pkgs.spicetify-cli;
      extensions = allExtensions;
      apps = [];
      theme = theme // {
        additionalCss = theme.additionalCss or "";
        extraCommands = theme.extraCommands or "";
      };
      customColorScheme = {};
      extraCommands = "";
      colorScheme = themeConfig.spicetify.colorScheme;
      config-xpui = xpui;
      wayland = true;
    };

  spotifyPackages = lib.mapAttrs (theme: polarities:
    lib.mapAttrs (_polarity: mkSpicedSpotify) polarities)
  themeConfigs;

  spotifyWrapper = pkgs.writeShellApplication {
    name = "spotify";
    text = ''
      state_file="$HOME/.local/state/theme-manager/current-theme-name.txt"
      theme_name="default-dark"
      if [ -s "$state_file" ]; then
        theme_name="$(cat "$state_file")"
      fi

      case "$theme_name" in
        catppuccin-light) exec ${spotifyPackages.catppuccin.light}/share/spotify/spotify "$@" ;;
        catppuccin-dark) exec ${spotifyPackages.catppuccin.dark}/share/spotify/spotify "$@" ;;
        default-light) exec ${spotifyPackages.default.light}/share/spotify/spotify "$@" ;;
        everforest-light) exec ${spotifyPackages.default.light}/share/spotify/spotify "$@" ;;
        rose-pine-light) exec ${spotifyPackages.default.light}/share/spotify/spotify "$@" ;;
        rose-pine-dark) exec ${spotifyPackages.default.dark}/share/spotify/spotify "$@" ;;
        *) exec ${spotifyPackages.default.dark}/share/spotify/spotify "$@" ;;
      esac
    '';
  };
in {
  programs.spicetify.enable = false;

  home.packages = [spotifyWrapper];

  xdg.desktopEntries.spotify = {
    name = "Spotify";
    genericName = "Music Player";
    exec = "spotify %U";
    terminal = false;
    icon = "spotify-client";
    categories = ["Audio" "Music" "Player" "AudioVideo"];
    mimeType = ["x-scheme-handler/spotify"];
  };
}
