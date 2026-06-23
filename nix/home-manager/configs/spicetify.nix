{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  themeConfigs = import ./shared/theme-configs.nix;

  getSchemeNameFromFile = schemeFile: let
    schemeContent = builtins.readFile "${pkgs.base16-schemes}/share/themes/${schemeFile}.yaml";
    schemeMatch = builtins.match ".*name: \"([^\"]+)\".*" schemeContent;
  in
    if schemeMatch != null
    then builtins.head schemeMatch
    else schemeFile;

  allThemeConfigs = lib.flatten (
    lib.mapAttrsToList (
      themeName: themeConfig: lib.mapAttrsToList (_: polarityConfig: polarityConfig) themeConfig
    )
    themeConfigs
  );

  currentThemeConfig =
    lib.findFirst (
      entry: (getSchemeNameFromFile entry.scheme) == config.lib.stylix.colors.scheme-name
    )
    themeConfigs.default.dark
    allThemeConfigs;
in {
  stylix.targets.spicetify.enable = false;

  programs.spicetify = {
    enable = true;
    wayland = true;

    theme = spicePkgs.themes.${currentThemeConfig.spicetifyTheme};
    colorScheme = currentThemeConfig.spicetifyColorScheme;
    customColorScheme = currentThemeConfig.spicetifyCustomColorScheme or {};

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
    ];
  };
}
