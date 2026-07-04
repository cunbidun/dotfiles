{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;

  themeConfigs = import ./shared/theme-configs.nix;
  chromeConfig = import ./chrome/config.nix;
  localChromeThemes = {
    everforest-light = import ./chrome/themes/everforest-light.nix {inherit pkgs;};
    gruvbox-light = import ./chrome/themes/gruvbox-light.nix {inherit pkgs;};
    nord-light = import ./chrome/themes/nord-light.nix {inherit pkgs;};
  };
  kittyNordLight = pkgs.writeText "kitty-nord-light.conf" ''
    background #e5e9f0
    foreground #2e3440
    selection_background #aebacf
    selection_foreground #2e3440
    cursor #2e3440
    cursor_text_color #e5e9f0
    url_color #60728c
    active_border_color #aebacf
    inactive_border_color #c2d0e7
    active_tab_background #e5e9f0
    active_tab_foreground #2e3440
    inactive_tab_background #c2d0e7
    inactive_tab_foreground #60728c
    tab_bar_background #c2d0e7
    color0 #e5e9f0
    color1 #99324b
    color2 #4f894c
    color3 #9a7500
    color4 #3b6ea8
    color5 #97365b
    color6 #398eac
    color7 #2e3440
    color8 #b8c5db
    color9 #99324b
    color10 #4f894c
    color11 #9a7500
    color12 #3b6ea8
    color13 #97365b
    color14 #398eac
    color15 #29838d
  '';

  kittyThemes = {
    catppuccin = {
      light = "Catppuccin-Latte.conf";
      dark = "Catppuccin-Mocha.conf";
    };
    everforest = {
      light = "everforest_light_hard.conf";
      dark = "everforest_dark_hard.conf";
    };
    gruvbox = {
      light = "GruvboxMaterialLightHard.conf";
      dark = "GruvboxMaterialDarkHard.conf";
    };
    nord = {
      light = "Nord.conf";
      dark = "Nord.conf";
    };
    rose-pine = {
      light = "rose-pine-dawn.conf";
      dark = "rose-pine.conf";
    };
  };

  kittyThemeFile = theme: polarity:
    if theme == "default"
    then config.themeManager.kitty.themePath polarity
    else if theme == "nord" && polarity == "light"
    then kittyNordLight
    else "${pkgs.kitty-themes}/share/kitty-themes/themes/${kittyThemes.${theme}.${polarity}}";

  runtimeTheme = theme: polarity: themeConfig: let
    extensionList =
      chromeConfig.baseExtensions
      ++ themeConfig.chromeExtensions
      ++ map (name: localChromeThemes.${name}.extension) (themeConfig.localChromeExtensions or []);
  in
    themeConfig
    // {
      inherit theme polarity extensionList;
      name = "${theme}-${polarity}";
      gtkColorScheme =
        if polarity == "light"
        then "prefer-light"
        else "prefer-dark";
      # No GTK theme name is set; rely solely on color-scheme (prefer-dark/
      # prefer-light) to drive app + Chrome dark/light, like catppuccin/default.
      gtkTheme = "";
      kittyTheme = kittyThemeFile theme polarity;
    };

  runtimeThemes = lib.mapAttrs (theme: polarities:
    lib.mapAttrs (polarity: themeConfig: runtimeTheme theme polarity themeConfig) polarities)
  themeConfigs;

  chromePolicyFiles = lib.listToAttrs (lib.flatten (lib.mapAttrsToList (theme: polarities:
    lib.mapAttrsToList (polarity: themeConfig: {
      name = ".local/share/theme-manager/chrome-policy/${theme}-${polarity}.json";
      value.text = chromeConfig.mkChromePolicy runtimeThemes.${theme}.${polarity}.extensionList;
    })
    polarities)
  themeConfigs));
in {
  config = lib.mkIf isLinux {
    services.theme-manager = {
      enable = true;
      enableTray = true;
      themes = builtins.attrNames themeConfigs;
    };

    home.file =
      chromePolicyFiles
      // {
        ".local/state/theme-manager/nix/themes.json".text = builtins.toJSON runtimeThemes;
      };

    home.activation.reapplyRuntimeTheme = lib.hm.dag.entryAfter ["vscodeProfiles"] ''
      if [ -S "$HOME/.local/share/theme-manager/socket" ]; then
        theme="$(${config.home.profileDirectory}/bin/themectl get-theme 2>/dev/null || true)"
        if [ -n "$theme" ]; then
          ${config.home.profileDirectory}/bin/themectl set-theme "$theme" >/dev/null || true
        fi
      fi
    '';
  };
}
