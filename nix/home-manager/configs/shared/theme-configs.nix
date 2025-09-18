# Centralized theme configuration
# This is the single source of truth for all theme mappings across the system
# Used by stylix.nix, hyprpanel.nix, and any other theme-aware configurations
# to get the theme name: https://github.com/tinted-theming/schemes
# to get hyprpanel themes: https://github.com/Jas-SinghFSU/HyprPanel/tree/master/themes
{
  nord = {
    light = {
      scheme = "nord-light";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Nord Light";
      nvimTheme = "nord";
      hyprpanelTheme = "nord";
    };
    dark = {
      scheme = "nord";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Nord";
      nvimTheme = "nord";
      hyprpanelTheme = "nord";
    };
  };
  catppuccin = {
    light = {
      scheme = "catppuccin-latte";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Catppuccin Latte";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
    };
    dark = {
      scheme = "catppuccin-mocha";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Catppuccin Mocha";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
    };
  };
  everforest = {
    light = {
      scheme = "everforest-light";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Light";
      nvimTheme = "everforest";
      hyprpanelTheme = "everforest";
    };
    dark = {
      scheme = "everforest-dark";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Dark";
      nvimTheme = "everforest";
      hyprpanelTheme = "everforest";
    };
  };
  onedark = {
    light = {
      scheme = "one-light";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Atom One Light";
      nvimTheme = "onelight";
      hyprpanelTheme = "one_dark";
    };
    dark = {
      scheme = "onedark";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Atom One Dark";
      nvimTheme = "onedark";
      hyprpanelTheme = "one_dark";
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Default Light Modern";
      nvimTheme = "vscode";
      hyprpanelTheme = "monochrome";
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Default Dark Modern";
      nvimTheme = "vscode";
      hyprpanelTheme = "monochrome";
    };
  };
}
