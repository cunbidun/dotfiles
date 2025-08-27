{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    keybindings = {
      "alt+v" = "paste_from_clipboard";
      "alt+c" = "copy_to_clipboard";
      "alt+f" = "show_scrollback";
      "alt+shift+f" = "launch --type=overlay --stdin-source=@screen_scrollback ${pkgs.fzf}/bin/fzf --no-sort --no-mouse --exact -i";
    };
    settings = {
      "confirm_os_window_close" = "0";
    };
  };
}
