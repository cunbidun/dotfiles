{inputs, ...}: {
  programs.hyprpanel = {
    enable = true;
    settings = {
      layout = {
        bar.layouts = {
          "0" = {
            left = ["dashboard" "workspaces"];
            middle = ["media"];
            right = ["volume" "systray" "notifications"];
          };
        };
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = true;

      menus.clock = {
        time = {
          military = true;
          hideSeconds = true;
        };
        weather.unit = "metric";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = true;
      theme.bar.transparent = true;
    };
  };
}
