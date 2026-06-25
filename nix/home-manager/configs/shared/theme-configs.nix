# Centralized theme configuration
# This is the single source of truth for all theme mappings across the system
# Used by theme-runtime.nix and any other theme-aware configurations
# to get the theme name: https://github.com/tinted-theming/schemes
{
  catppuccin = {
    light = {
      scheme = "catppuccin-latte";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Catppuccin Latte";
      vicinaeTheme = "catppuccin-latte";
      spicetify = {
        theme = "catppuccin";
        colorScheme = "latte";
      };
      chromeExtension = "jhjnalhegpceacdhbplhnakmkdliaddd"; # Catppuccin extension
    };
    dark = {
      scheme = "catppuccin-mocha";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Catppuccin Mocha";
      vicinaeTheme = "catppuccin-mocha";
      spicetify = {
        theme = "catppuccin";
        colorScheme = "mocha";
      };
      chromeExtension = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; # Catppuccin extension
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Light Modern";
      vicinaeTheme = "theme-manager-default-light";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtension = null; # Default theme - no specific extension needed
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Dark Modern";
      vicinaeTheme = "theme-manager-default-dark";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtension = null; # Default theme - no specific extension needed
    };
  };
}
