# Centralized theme configuration
# This is the single source of truth for all theme mappings across the system
# Used by stylix.nix and any other theme-aware configurations
# to get the theme name: https://github.com/tinted-theming/schemes
# to get hyprpanel themes: https://github.com/Jas-SinghFSU/HyprPanel/tree/master/themes
{
  catppuccin = {
    light = {
      scheme = "catppuccin-latte";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Catppuccin Latte";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
      vicinaeTheme = "catppuccin-latte";
      chromeExtension = "jhjnalhegpceacdhbplhnakmkdliaddd"; # Catppuccin extension
    };
    dark = {
      scheme = "catppuccin-mocha";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Catppuccin Mocha";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
      vicinaeTheme = "catppuccin-mocha";
      chromeExtension = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; # Catppuccin extension
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Default Light Modern";
      nvimTheme = "vscode_light";
      hyprpanelTheme = "monochrome";
      vicinaeTheme = "vicinae-light";
      chromeExtension = null; # Default theme - no specific extension needed
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Default Dark Modern";
      nvimTheme = "vscode_dark";
      hyprpanelTheme = "monochrome";
      vicinaeTheme = "vicinae-dark";
      chromeExtension = null; # Default theme - no specific extension needed
    };
  };
}
