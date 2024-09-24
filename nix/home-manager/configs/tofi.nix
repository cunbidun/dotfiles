{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.tofi = {
    enable = true;
    settings = {
      hide-cursor = true;

      # Location and orientation
      anchor = "top";
      width = "100%";
      height = 24;
      horizontal = true;

      # Font
      font = "SFMono Nerd Font";
      min-input-width = 240;

      # Appearance
      border-width = 0;
      outline-width = 0;
      padding-top = 3;
      padding-left = 3;
      padding-bottom = 0;

      # Behavior
      drun-launch = true;
      result-spacing = 25;

      # Selection
      selection-background-padding = "0,5";
      prompt-padding = 8;
      prompt-background-padding = "0,8";

      # Colors
      selection-color = lib.mkForce "#${config.lib.stylix.colors.base00}";
      selection-background = lib.mkForce "#${config.lib.stylix.colors.base0C}";
    };
  };
}
