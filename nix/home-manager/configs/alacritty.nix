{ color-scheme, ... } : {
  settings = {
    live_config_reload = true;
    colors = color-scheme.alacritty; 
    env = {
      TERM = "alacritty";
    };
    font = {
      size = 10;
      normal = {
        family = "SauceCodePro Nerd Font Mono";
      };
    };
    window = {
      decorations = "none";
      dynamic_padding = true;
      opacity = 0.85;
      dimensions = [
        {
          lines = 3;
          columns = 200;
        }
      ];
    };
    keyboard = {
      bindings = [
        {
          key = "V";
          mods = "Alt";
          action = "Paste";
        }
        {
          key = "C";
          mods = "Alt";
          action = "Copy";
        }
        {
          key = "K";
          mods = "Control";
          chars = "\\x0c";
        }
      ];
    };
  };
}