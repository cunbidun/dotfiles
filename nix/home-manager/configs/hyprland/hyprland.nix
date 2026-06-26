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
  hyprlandConfig = "${config.home.homeDirectory}/dotfiles/nix/home-manager/configs/hyprland/lua";
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

  xdg.configFile."hypr/hyprland.lua".text = ''
    require("user.hyprland")
  '';

  xdg.configFile."hypr/user/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${hyprlandConfig}/hyprland.lua";
  xdg.configFile."hypr/user/theme.lua".source = config.lib.file.mkOutOfStoreSymlink "${hyprlandConfig}/theme.lua";

  xdg.configFile."hypr/user/command.lua".text = ''
    return {
      increase_volume = "${lib.getExe scripts.increase-volume}",
      decrease_volume = "${lib.getExe scripts.decrease-volume}",
      toggle_volume = "${lib.getExe scripts.toggle-volume}",
      playerctl = "${lib.getExe pkgs.playerctl}",
      hyprland_mode = "${lib.getExe scripts.hyprland-mode}",
      screenshot_copy_upload = "${lib.getExe scripts."screenshot-copy-upload"}",
      wsctl = "${lib.getExe scripts.wsctl}",
    }
  '';

  xdg.configFile."hypr/user/plugin.lua".text = ''
    return {
      hyprfocus = "${hyprfocus}/lib/libhyprfocus.so",
    }
  '';
}
