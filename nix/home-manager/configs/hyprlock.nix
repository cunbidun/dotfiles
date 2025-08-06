{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      background = {
        path = lib.mkForce "screenshot";
        blur_passes = 3;
        blur_size = 5;
        brightness = 0.3;
      };

      input-field = {
        size = "300, 50";
        valign = "bottom";
        position = "0%, 10%";
        outline_thickness = 0;
        fade_on_empty = true;
        placeholder_text = "Enter Password";
        dots_spacing = 0.1;
        dots_center = true;
      };

      animations = {
        enabled = false;
      };

      label = [
        # Time
        {
          text = "cmd[update:1000] echo \"$(date +\"%-I:%M:%S %p\")\"";
          color = "rgba(200, 200, 200, 1.0)";
          font_size = 24;
          font_family = "SFMono Nerd Font";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          text = "cmd[update:43200000] echo \"$(date +\"%A, %B %e, %Y\")\"";
          color = "rgba(200, 200, 200, 1.0)";
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
