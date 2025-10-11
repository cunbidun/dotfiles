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
      vicinaeTheme = "nord_light";
    };
    dark = {
      scheme = "nord";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Nord";
      nvimTheme = "nord";
      hyprpanelTheme = "nord";
      vicinaeTheme = "nord_dark";
      fzf_theme = "--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 --color=selected-bg:#BCC0CC --color=border:#9CA0B0,label:#4C4F69";
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
    };
    dark = {
      scheme = "catppuccin-mocha";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Catppuccin Mocha";
      nvimTheme = "catppuccin";
      hyprpanelTheme = "catppuccin_mocha";
      vicinaeTheme = "catppuccin-mocha";
      fzf_theme = "--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4";
    };
  };
  everforest = {
    light = {
      scheme = "everforest-light";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Light";
      nvimTheme = "everforest";
      hyprpanelTheme = "everforest";
      vicinaeTheme = "vicinae-light";
    };
    dark = {
      scheme = "everforest-dark";
      wallpaper = ../../../../wallpapers/fog_forest_2.png;
      vscodeTheme = "Everforest Dark";
      nvimTheme = "everforest";
      hyprpanelTheme = "everforest";
      vicinaeTheme = "vicinae-dark";
    };
  };
  onedark = {
    light = {
      scheme = "one-light";
      wallpaper = ../../../../wallpapers/thuonglam.jpeg;
      vscodeTheme = "Atom One Light";
      nvimTheme = "onelight";
      hyprpanelTheme = "one_dark";
      vicinaeTheme = "one-dark";
    };
    dark = {
      scheme = "onedark";
      wallpaper = ../../../../wallpapers/Astronaut.png;
      vscodeTheme = "Atom One Dark";
      nvimTheme = "onedark";
      hyprpanelTheme = "one_dark";
      vicinaeTheme = "one-dark";
    };
  };
  default = {
    light = {
      scheme = "standardized-light";
      wallpaper = ../../../../wallpapers/big-sur-mountains-day.jpg;
      vscodeTheme = "Default Light Modern";
      nvimTheme = "vscode";
      hyprpanelTheme = "monochrome";
      vicinaeTheme = "vicinae-light";
    };
    dark = {
      scheme = "standardized-dark";
      wallpaper = ../../../../wallpapers/big-sur-mountains-night.jpg;
      vscodeTheme = "Default Dark Modern";
      nvimTheme = "vscode";
      hyprpanelTheme = "monochrome";
      vicinaeTheme = "vicinae-dark";
    };
  };
}
