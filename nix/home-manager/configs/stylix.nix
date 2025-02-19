{
  inputs,
  pkgs,
  lib,
  ...
}: let
  theme-name = "standardized-dark";
  # theme-name = "standardized-light";
in {
  dconf.settings."org/gnome/desktop/interface".color-scheme =
    if theme-name == "standardized-dark"
    then (lib.mkForce "prefer-dark")
    else (lib.mkForce "prefer-light");
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${theme-name}.yaml";

    image =
      if theme-name == "standardized-dark"
      then ../../../wallpapers/Astronaut.png
      else ../../../wallpapers/thuonglam.jpeg;

    targets = {
      waybar.enable = false;
      vscode.enable = false;
      gnome.enable = true;
      kde.enable = true;
      gtk.enable = true;
    };

    # https://github.com/phisch/phinger-cursors
    cursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 24;
    };

    opacity = {
      terminal = 0.85;
    };

    fonts = {
      sizes = {
        applications = 11;
        terminal = 10;
        desktop = 10;
      };
      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.ny-nerd;
        name = "NewYork Nerd Font";
      };

      sansSerif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };

      monospace = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
        name = "SFMono Nerd Font";
      };
    };
  };
}
