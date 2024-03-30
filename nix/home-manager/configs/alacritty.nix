{ pkgs, color-scheme, ... }: {
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      live_config_reload = true;
      colors.bright = color-scheme.alacritty-colors.bright;
      colors.cursor = color-scheme.alacritty-colors.cursor;
      colors.normal = color-scheme.alacritty-colors.normal;
      colors.primary = color-scheme.alacritty-colors.primary;
      colors.draw_bold_text_with_bright_colors = true;
      env = { TERM = "alacritty"; };
      font = {
        size = 10;
        normal = { family = "SauceCodePro Nerd Font Mono"; };
      };
      window = {
        decorations = "none";
        dynamic_padding = true;
        opacity = 0.85;
      };
      keyboard = {
        bindings = [
          {
            key = "V";
            mods = "Alt";
            action = "Paste";
          }
          {
            key = "C";
            mods = "Alt";
            action = "Copy";
          }
        ];
      };
    };
  };
}
