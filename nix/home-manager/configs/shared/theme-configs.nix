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
      vicinaeTheme = "onenord_light";
      chromeExtension = "abehfkkfjlplnjadfcjiflnejblfmmpj"; # Nord extension
    };
    dark = {
      scheme = "nord";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Nord";
      nvimTheme = "nord";
      hyprpanelTheme = "nord";
      vicinaeTheme = "nord_dark";
      chromeExtension = "abehfkkfjlplnjadfcjiflnejblfmmpj"; # Nord extension
    };
  };
  catppuccin = {
    light = {
      scheme = "catppuccin-latte";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Catppuccin Latte";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
      vicinaeTheme = "catppuccin_latte";
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
  everforest = {
    light = {
      scheme = "everforest-light";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Light";
      nvimTheme = "everforest_light";
      hyprpanelTheme = "everforest";
      vicinaeTheme = "vicinae-light";
      chromeExtension = "dlcadbmcfambdjhecipbnolmjchgnode"; # Everforest Chrome Theme
    };
    dark = {
      scheme = "everforest-dark";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Dark";
      nvimTheme = "everforest";
      hyprpanelTheme = "everforest";
      vicinaeTheme = "vicinae-dark";
      chromeExtension = "dlcadbmcfambdjhecipbnolmjchgnode"; # Everforest Chrome Theme
    };
  };
  onedark = {
    light = {
      scheme = "one-light";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Atom One Light";
      nvimTheme = "one_light";
      hyprpanelTheme = "one_dark";
      vicinaeTheme = "one-dark";
      chromeExtension = "ajamefcbfaiolpnjelkafhjdninoclhc"; # seri's dark theme (Atom One Dark based)
    };
    dark = {
      scheme = "onedark";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Atom One Dark";
      nvimTheme = "onedark";
      hyprpanelTheme = "one_dark";
      vicinaeTheme = "one-dark";
      chromeExtension = "kjboibophcgchimahpicagheccpnjnhi"; # seri's dark theme (Atom One Dark based)
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
