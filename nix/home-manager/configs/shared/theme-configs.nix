# Centralized theme configuration
# This is the single source of truth for all theme mappings across the system
# Used by theme-runtime.nix and any other theme-aware configurations
# to get the theme name: https://github.com/tinted-theming/schemes
{
  rose-pine = {
    light = {
      scheme = "rose-pine-dawn";
      wallpaper = ../../../../wallpapers/rose-pine-dawn-wallpaper.jpg;
      vscodeTheme = "Rosé Pine Dawn";
      vicinaeTheme = "rose-pine-dawn";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = ["faffeempkcpjhcmfpglpkdpbkdmbpaab"];
    };
    dark = {
      scheme = "rose-pine";
      wallpaper = ../../../../wallpapers/rose-pine-moon-wallpaper.jpeg;
      vscodeTheme = "Rosé Pine";
      vicinaeTheme = "rose-pine";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = ["noimedcjdohhokijigpfcbjcfcaaahej"];
    };
  };
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
      chromeExtensions = ["jhjnalhegpceacdhbplhnakmkdliaddd"]; # Catppuccin extension
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
      chromeExtensions = ["bkkmolkhemgaeaeggcmfbghljjjoofoh"]; # Catppuccin extension
    };
  };
  everforest = {
    light = {
      scheme = "everforest";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Light";
      vicinaeTheme = "theme-manager-everforest-light";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      localChromeExtensions = ["everforest-light"];
      chromeExtensions = [
      ];
    };
    dark = {
      scheme = "everforest-dark-hard";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Dark";
      vicinaeTheme = "theme-manager-everforest-dark";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = [
        "dlcadbmcfambdjhecipbnolmjchgnode" # Everforest Chrome Theme
      ];
    };
  };
  gruvbox = {
    light = {
      scheme = "gruvbox-material-light-hard";
      wallpaper = ../../../../wallpapers/gruvbox-trees.png;
      vscodeTheme = "Gruvbox Material Light";
      vicinaeTheme = "theme-manager-gruvbox-light";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      localChromeExtensions = ["gruvbox-light"];
      chromeExtensions = [
      ];
    };
    dark = {
      scheme = "gruvbox-material-dark-hard";
      wallpaper = ../../../../wallpapers/gruvbox-trees.png;
      vscodeTheme = "Gruvbox Material Dark";
      vicinaeTheme = "theme-manager-gruvbox-dark";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = [
        "fjofdcgahcnlkdjapcbeonbnmjdnfcki"
      ];
    };
  };
  nord = {
    light = {
      scheme = "nord-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Nord Light";
      vicinaeTheme = "nord-light";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      localChromeExtensions = ["nord-light"];
      chromeExtensions = [
      ];
    };
    dark = {
      scheme = "nord";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Nord";
      vicinaeTheme = "nord";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = [
        "honjmojpikfebagfakclmgbcchedenbo"
      ];
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/tree-light.jpg;
      vscodeTheme = "Light Modern";
      vicinaeTheme = "theme-manager-default-light";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = []; # Default theme - no specific extension needed
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/tree-dark.jpg;
      vscodeTheme = "Dark Modern";
      vicinaeTheme = "theme-manager-default-dark";
      spicetify = {
        theme = "default";
        colorScheme = "Ocean";
      };
      chromeExtensions = []; # Default theme - no specific extension needed
    };
  };
}
