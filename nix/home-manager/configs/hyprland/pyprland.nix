{pkgs, ...}: {
  xdg.configFile."hypr/pyprland.toml".source = (pkgs.formats.toml {}).generate "pyprland.toml" {
    pyprland = {
      plugins = [
        "scratchpads"
        "toggle_special"
      ];
    };
    scratchpads = {
      term = {
        command = "alacritty -t __scratchpad";
        animation = "";
        lazy = true;
        unfocus = "";
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      # messenger = {
      #   command = "firefoxpwa site launch 01JEQ82MQK9NCAQ8DCVVPYMJFX";
      #   animation = "";
      #   unfocus = "";
      #   lazy = true;
      #   size = "50% 50%";
      #   position = "25% 25%";
      #   excludes = "*";
      #   class = "FFPWA-01JEQ82MQK9NCAQ8DCVVPYMJFX";
      #   match_by = "class";
      #   hysteresis = 0;
      #   process_tracking = false;
      # };

      spotify = {
        command = "spotify";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      signal = {
        command = "signal-desktop";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      file = {
        command = "command ";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
        match_by = "class";
        process_tracking = false;
        class = "org.gnome.Nautilus";
      };

      obsidian = {
        command = "obsidian";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "75% 75%";
        position = "12% 12%";
        excludes = "*";
        hysteresis = 0;
      };
    };
  };
}
