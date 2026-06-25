{...}: {
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
}
