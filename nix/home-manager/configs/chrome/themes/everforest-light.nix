{pkgs}: let
  mkThemeCrx = import ../theme-crx.nix {inherit pkgs;};
in
  mkThemeCrx {
    id = "odibdilhnhgpmekdknegmafphclfcalk";
    name = "Theme Manager Everforest Light";
    packageName = "theme-manager-everforest-light";
    publicKey = builtins.concatStringsSep "" [
      "MIIBIjANBgkqhkiG9w0BAQEF"
      "AAOCAQ8AMIIBCgKCAQEAuaDP"
      "Xs7I3dZe+Z5oWdulHtfdENOg"
      "Oscd0mH8G3KThqngbU90fP1F" # pragma: allowlist secret
      "z9quzPr87OreXA5LBhVPiH7v"
      "lf1KKNtXT5iOcePdvgtVISXh"
      "YWXfKljs/epFeLXoFyu4ZsPv"
      "TtQPXekTydGYaF6cW0k6Q1bR"
      "O4ySzkKWcq9Fb2RL/FsnVJZ9"
      "w1D8Ifm5r5cnmcJh59K/kZbw"
      "tHgNcJFSsPCUu6lRryGxY1wt" # pragma: allowlist secret
      "3jEoOQZLS6+1EdB2ruCWojU+"
      "lhhdXO3qiqhQ0yc3G2wmS3wq"
      "YGg4/9sr/4WbYkQKWvVXnHku"
      "zKA/Csla3dqr1BDyc3e+n/yG"
      "a8LlLkrCjm8HGIwhxTFlko5S"
      "6QIDAQAB"
    ];
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
