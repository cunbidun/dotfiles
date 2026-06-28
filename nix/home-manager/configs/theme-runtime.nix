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
  };

  kittyThemes = {
    catppuccin = {
      light = "Catppuccin-Latte.conf";
      dark = "Catppuccin-Mocha.conf";
    };
    everforest = {
      light = "everforest_light_hard.conf";
      dark = "everforest_dark_hard.conf";
    };
    rose-pine = {
      light = "rose-pine-dawn.conf";
      dark = "rose-pine.conf";
    };
  };

  kittyThemeFile = theme: polarity:
    if theme == "default"
    then config.themeManager.kitty.themePath polarity
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
