# Lua config docs:
# https://wiki.hypr.land/Configuring/Start/
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  scripts = import ../../scripts.nix {pkgs = pkgs;};
  system = pkgs.stdenv.hostPlatform.system;

  colors = config.lib.stylix.colors;
  rgb = color: "rgb(${color})";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    package = inputs.hyprland.packages.${system}.hyprland;

    plugins = [];

    # Hyprland 0.55+ loads hyprland.lua instead of hyprland.conf when present.
    # Keep the HM module enabled for the package/session integration, but put the
    # real compositor config in xdg.configFile below.
    settings = {};
    extraConfig = "";
  };

  xdg.configFile."hypr/hyprland.lua".source = ./lua/hyprland.lua;

  xdg.configFile."hypr/nix.lua".text = ''
    return {
      colors = {
        background = "${rgb colors.base07}",
        group_active = "${rgb colors.base0C}",
        group_inactive = "${rgb colors.base01}",
        group_text = "${rgb colors.base01}",
        group_text_inactive = "${rgb colors.base06}",
        border_active = "${rgb colors.base0D}",
        border_inactive = "${rgb colors.base04}",
        border_locked_active = "${rgb colors.base0C}",
        shadow = "rgba(${colors.base07}99)",
      },

      commands = {
        increase_volume = "${lib.getExe scripts.increase-volume}",
        decrease_volume = "${lib.getExe scripts.decrease-volume}",
        toggle_volume = "${lib.getExe scripts.toggle-volume}",
        hyprland_mode = "${lib.getExe scripts.hyprland-mode}",
        screenshot_copy_upload = "${lib.getExe scripts."screenshot-copy-upload"}",
        wsctl = "${lib.getExe scripts.wsctl}",
      },
    }
  '';
}
