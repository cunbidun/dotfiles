{
  inputs,
  pkgs,
  lib,
  project_root,
  ...
}: {
  stylix = {
    enable = true;
    image = ../../../wallpapers/others/QgdxHBX.jpeg;
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-light-hard.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/default-light.yaml";

    targets = {
      gnome.enable = true;
      kde.enable = true;
      hyprpaper.enable = true;
      bat.enable = true;

      waybar.enable = false;
      vscode.enable = false;
      nixvim.enable = false;
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
