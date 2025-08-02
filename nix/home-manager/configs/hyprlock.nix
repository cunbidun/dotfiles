{
  pkgs,
  inputs,
  lib,
  ...
}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      background = lib.mkForce {
        color = "rgba(25, 20, 20, 1.0)";
        path = "screenshot";
        blur_passes = 2;
        brightness = 0.5;
      };

      input-field = lib.mkForce [
        {
          size = "300, 50";
          valign = "bottom";
          position = "0%, 10%";
          outline_thickness = 0;
          fade_on_empty = true;
          placeholder_text = "Enter Password";
          dots_spacing = 0.1;
          dots_center = true;
          color = "rgb(202, 211, 245)";
          check_color = "rgb(202, 211, 245)";
          fail_color = "rgb(202, 211, 245)";
        }
      ];

      animations = {
        enabled = false;
      };

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
