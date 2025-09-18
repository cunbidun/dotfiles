{
  pkgs,
  inputs,
  ...
}: {
  programs.hyprpanel.enable = true;

  # Add missing required dependencies for HyprPanel
  home.packages = with pkgs; [
    # Required dependencies that were missing
    libgtop           # System monitoring library
    gvfs              # GNOME Virtual File System
    gtksourceview3    # Text widget with syntax highlighting
    libsoup_3         # HTTP library (libsoup3)
    
    # Optional but useful dependencies
    python312Packages.gpustat  # GPU usage tracking (NVidia only)
    wf-recorder       # Screen recorder for Wayland
    power-profiles-daemon  # Switch power profiles (if you want this)
  ];
}
