{
  lib,
  config,
  ...
}: let
  themeDir = "${config.home.homeDirectory}/.local/share/theme-manager/kitty";
  kittyThemePath = polarity: "${themeDir}/theme-manager-default-${polarity}.conf";
in {
  options.themeManager.kitty.themePath = lib.mkOption {
    type = lib.types.functionTo lib.types.str;
    default = kittyThemePath;
    readOnly = true;
    description = "Return theme-manager's kitty theme path for a polarity.";
  };

  config = {
    programs.kitty = {
      enable = true;
      keybindings = {
        "alt+v" = "paste_from_clipboard";
        "alt+c" = "copy_to_clipboard";
      };
      settings = {
        "confirm_os_window_close" = "0";
        "auto_reload_config" = "-1";
        "font_family" = "SFMono Nerd Font";
        "font_size" = "10";
        "background_opacity" = "0.75";
        "dynamic_background_opacity" = "yes";
      };
      extraConfig = ''
        include ~/.local/state/theme-manager/kitty-theme.conf
      '';
    };

    home.file = {
      ".local/share/theme-manager/kitty/theme-manager-default-light.conf".source = ./default-light.conf;
      ".local/share/theme-manager/kitty/theme-manager-default-dark.conf".source = ./default-dark.conf;
    };
  };
}
