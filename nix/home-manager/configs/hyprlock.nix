{lib, ...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = lib.mkForce {
        blur_passes = 2;
        brightness = 0.5;
      };

      input-field = lib.mkForce [
        {
          size = "300, 50";
          valign = "bottom";
          position = "0%, 10%";
          outline_thickness = 1;
          fade_on_empty = true;
          placeholder_text = "Enter Password";
          dots_spacing = 0.1;
          dots_center = true;
          dots_fade_time = 100;
          shadow_color = "rgba(0, 0, 0, 0.1)";
          shadow_size = 7;
          shadow_passes = 2;
        }
      ];

      label = [
        # Time
        {
          text = "cmd[update:1000] echo \"$(date +\"%-I:%M:%S %p\")\"";
          color = "rgb(202, 211, 245)";
          font_size = 24;
          font_family = "SFMono Nerd Font";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          text = "cmd[update:43200000] echo \"$(date +\"%A, %B %e, %Y\")\"";
          color = "rgb(202, 211, 245)";
          font_size = 16;
          font_family = "SFMono Nerd Font";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
