{pkgs}: let
  mkThemeCrx = import ../theme-crx.nix {inherit pkgs;};
in
  mkThemeCrx {
    id = "aobnncoakhaododnlkmkhnkghpbplgjf";
    name = "Theme Manager Gruvbox Light";
    packageName = "theme-manager-gruvbox-light";
    version = "1.0.0";
    keyName = "gruvbox-rsa";
    theme = {
      colors = {
        frame = [235 219 178];
        frame_inactive = [235 219 178];
        toolbar = [251 241 199];
        tab_text = [60 56 54];
        tab_background_text = [124 111 100];
        bookmark_text = [60 56 54];
        toolbar_text = [60 56 54];
        omnibox_background = [242 229 188];
        omnibox_text = [60 56 54];
        ntp_background = [251 241 199];
        ntp_text = [60 56 54];
        ntp_link = [69 133 136];
        button_background = [251 241 199];
      };
      tints.buttons = [(-1) (-1) 0.25];
      properties.ntp_logo_alternate = 0;
    };
  }
