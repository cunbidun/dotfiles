{
  config,
  pkgs,
  lib,
  project_root,
  userdata,
  inputs,
  ...
}: {
  # Add HyprPanel to home packages
  home.packages = with pkgs; [
    inputs.hyprpanel.packages.${pkgs.system}.default
  ];

  # HyprPanel configuration
  # The configuration will be managed by HyprPanel itself after first run
  # You can customize it through the GUI or by editing ~/.config/hyprpanel/config.json
  
  # Optional: Add HyprPanel to autostart (if not using systemd)
  # This is typically handled by your window manager's autostart or systemd user services
}
