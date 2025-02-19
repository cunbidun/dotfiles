{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      general.live_config_reload = true;
      colors.draw_bold_text_with_bright_colors = true;
      env = {TERM = "alacritty";};
      font = {
        normal = {family = "SFMono Nerd Font";};
      };
      window = {
        decorations = "none";
        dynamic_padding = true;
      };
    };
  };
}
