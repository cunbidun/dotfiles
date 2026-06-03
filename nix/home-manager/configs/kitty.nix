{config, ...}: let
  c = config.lib.stylix.colors;
in {
  programs.kitty = {
    enable = true;
    keybindings = {
      "alt+v" = "paste_from_clipboard";
      "alt+c" = "copy_to_clipboard";
    };
    settings = {
      "confirm_os_window_close" = "0";

      # Colors (inlined to avoid include /nix/store/... which causes inotify watch exhaustion)
      background = "#${c.base00}";
      foreground = "#${c.base05}";
      selection_background = "#${c.base02}";
      selection_foreground = "#${c.base05}";
      cursor = "#${c.base05}";
      cursor_text_color = "#${c.base00}";
      url_color = "#${c.base04}";
      active_border_color = "#${c.base03}";
      inactive_border_color = "#${c.base01}";
      wayland_titlebar_color = "#${c.base00}";
      macos_titlebar_color = "#${c.base00}";
      active_tab_background = "#${c.base00}";
      active_tab_foreground = "#${c.base05}";
      inactive_tab_background = "#${c.base01}";
      inactive_tab_foreground = "#${c.base04}";
      tab_bar_background = "#${c.base01}";

      # 16 terminal colors
      color0 = "#${c.base00}";
      color1 = "#${c.base08}";
      color2 = "#${c.base0B}";
      color3 = "#${c.base0A}";
      color4 = "#${c.base0D}";
      color5 = "#${c.base0E}";
      color6 = "#${c.base0C}";
      color7 = "#${c.base05}";
      color8 = "#${c.base03}";
      color9 = "#${c.base08}";
      color10 = "#${c.base0B}";
      color11 = "#${c.base0A}";
      color12 = "#${c.base0D}";
      color13 = "#${c.base0E}";
      color14 = "#${c.base0C}";
      color15 = "#${c.base07}";

      # Extended base16 colors
      color16 = "#${c.base09}";
      color17 = "#${c.base0F}";
      color18 = "#${c.base01}";
      color19 = "#${c.base02}";
      color20 = "#${c.base04}";
      color21 = "#${c.base06}";
    };
  };
}
