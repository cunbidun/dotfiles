{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    keybindings = {
      "super+v" = "paste_from_selection";
      "super+c" = "copy_to_clipboard";
    };
    settings = {
      "confirm_os_window_close" = "0";
    };
  };
}
