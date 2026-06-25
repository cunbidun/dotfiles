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
  hyprfocus = inputs.hyprfocus.packages.${system}.hyprfocus;
in {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
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
        background = "rgb(1C1C1E)",
        group_active = "rgb(0A84FF)",
        group_inactive = "rgb(2C2C2E)",
        group_text = "rgb(FFFFFF)",
        group_text_inactive = "rgb(FFFFFF)",
        border_active = "rgb(0A84FF)",
        border_inactive = "rgb(545458)",
        border_locked_active = "rgb(30D158)",
        shadow = "rgba(1C1C1E99)",
      },

      commands = {
        increase_volume = "${lib.getExe scripts.increase-volume}",
        decrease_volume = "${lib.getExe scripts.decrease-volume}",
        toggle_volume = "${lib.getExe scripts.toggle-volume}",
        playerctl = "${lib.getExe pkgs.playerctl}",
        hyprland_mode = "${lib.getExe scripts.hyprland-mode}",
        screenshot_copy_upload = "${lib.getExe scripts."screenshot-copy-upload"}",
        wsctl = "${lib.getExe scripts.wsctl}",
      },

      plugins = {
        hyprfocus = "${hyprfocus}/lib/libhyprfocus.so",
      },
    }
  '';
}
