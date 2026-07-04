{pkgs}: let
  mkThemeCrx = import ../theme-crx.nix {inherit pkgs;};
in
  mkThemeCrx {
    id = "daeonnbdmmldocjppdkobjbbknenbijh";
    name = "Theme Manager Nord Light";
    packageName = "theme-manager-nord-light";
    version = "1.0.0";
    keyName = "nord-rsa";
    theme = {
      colors = {
        frame = [216 222 233];
        frame_inactive = [216 222 233];
        toolbar = [236 239 244];
        tab_text = [46 52 64];
        tab_background_text = [96 114 140];
        bookmark_text = [46 52 64];
        toolbar_text = [46 52 64];
        omnibox_background = [229 233 240];
        omnibox_text = [46 52 64];
        ntp_background = [236 239 244];
        ntp_text = [46 52 64];
        ntp_link = [94 129 172];
        button_background = [236 239 244];
      };
      tints.buttons = [(-1) (-1) 0.25];
      properties.ntp_logo_alternate = 0;
    };
  }
