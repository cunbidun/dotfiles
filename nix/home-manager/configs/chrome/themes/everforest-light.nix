{pkgs}: let
  mkThemeCrx = import ../theme-crx.nix {inherit pkgs;};
in
  mkThemeCrx {
    id = "odibdilhnhgpmekdknegmafphclfcalk";
    name = "Theme Manager Everforest Light";
    packageName = "theme-manager-everforest-light";
    version = "1.0.0";
    theme = {
      colors = {
        frame = [242 239 223];
        frame_inactive = [242 239 223];
        toolbar = [255 251 239];
        tab_text = [92 106 114];
        tab_background_text = [130 145 129];
        bookmark_text = [92 106 114];
        toolbar_text = [92 106 114];
        omnibox_background = [248 245 228];
        omnibox_text = [92 106 114];
        ntp_background = [255 251 239];
        ntp_text = [92 106 114];
        ntp_link = [58 148 197];
        button_background = [255 251 239];
      };
      tints.buttons = [(-1) (-1) 0.25];
      properties.ntp_logo_alternate = 0;
    };
  }
