# Centralized theme configuration
# This is the single source of truth for all theme mappings across the system
# Used by stylix.nix and any other theme-aware configurations
# to get the theme name: https://github.com/tinted-theming/schemes
{
  catppuccin = {
    light = {
      scheme = "catppuccin-latte";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Catppuccin Latte";
      vicinaeTheme = "catppuccin-latte";
      spicetifyTheme = "catppuccin";
      spicetifyColorScheme = "latte";
      chromeExtension = "jhjnalhegpceacdhbplhnakmkdliaddd"; # Catppuccin extension
    };
    dark = {
      scheme = "catppuccin-mocha";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Catppuccin Mocha";
      vicinaeTheme = "catppuccin-mocha";
      spicetifyTheme = "catppuccin";
      spicetifyColorScheme = "mocha";
      chromeExtension = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; # Catppuccin extension
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Light Modern";
      vicinaeTheme = "vicinae-light";
      spicetifyTheme = "default";
      spicetifyColorScheme = "custom";
      spicetifyCustomColorScheme = {
        text = "1d1d1f";
        subtext = "515154";
        main = "f5f5f7";
        sidebar = "ffffff";
        player = "ffffff";
        card = "ffffff";
        shadow = "d2d2d7";
        selected-row = "e8e8ed";
        button = "007aff";
        button-active = "005ecb";
        button-disabled = "c7c7cc";
        tab-active = "e8e8ed";
        notification = "ffffff";
        notification-error = "ff3b30";
        misc = "d2d2d7";
      };
      chromeExtension = null; # Default theme - no specific extension needed
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Dark Modern";
      vicinaeTheme = "vicinae-dark";
      spicetifyTheme = "default";
      spicetifyColorScheme = "Ocean";
      chromeExtension = null; # Default theme - no specific extension needed
    };
  };
}
