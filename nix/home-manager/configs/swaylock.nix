{...}: {
  programs.swaylock = {
    enable = true;
    settings = {
      clock = true;
      screenshots = true;
      indicator = true;
      "indicator-radius" = 100;
      "indicator-thickness" = 10;
      "indicator-caps-lock" = true;
      "effect-blur" = "7x5";
      "effect-vignette" = "0.5:0.5";
      grace = 0;
      "fade-in" = 0.2;
      "line-uses-inside" = true;
      font = "SFMono Nerd Font";
      "font-size" = 20;
    };
  };
}
