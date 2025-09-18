{
  pkgs,
  inputs,
  ...
}: {
  programs.hyprpanel = {
    enable = true;

    settings = {
      bar = {
        launcher = {
          icon = "";
          autoDetectIcon = false;
        };

        workspaces = {
          show_icons = false;
          show_numbered = true;
          numbered_active_indicator = "underline";
          workspaces = 9;
        };
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
        bar.transparent = true;
        font = {
          name = "CasSFMono Nerd Font";
          size = "13px";
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
