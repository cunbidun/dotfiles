{
  pkgs,
  inputs,
  ...
}: {
  programs.hyprpanel = {
    enable = true;

    settings = {
      bar = {
        workspaces = {
          show_icons = false;
          show_numbered = true;
          numbered_active_indicator = "underline";
          workspaces = 9;
          ignored = "-\\d+";
        };
        border.width = "0px";
      };

      menus = {
        clock = {
          time = {
            military = true;
            hideSeconds = true;
          };
        };
      };

      theme = {
        bar.transparent = false;
        font = {
          name = "SFMono Nerd Font";
          size = "13px";
          weight = "400";
        };
      };
    };
  };

  # Add missing required dependencies for HyprPanel
  home.packages = with pkgs; [
    # Required dependencies
    libgtop
    gnome.gvfs
    gtksourceview # gtksourceview3 maps to gtksourceview
    libsoup_3 # libsoup3 maps to libsoup_3

    # Optional dependencies
    python312Packages.gpustat # python-gpustat for GPU usage tracking
    wf-recorder # For built-in screen recorder
    power-profiles-daemon # Switch power profiles
  ];
}
