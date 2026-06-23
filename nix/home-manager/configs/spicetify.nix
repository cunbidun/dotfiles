{
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  stylix.targets.spicetify.enable = false;

  programs.spicetify = {
    enable = true;
    wayland = true;

    theme = spicePkgs.themes.default;
    colorScheme = "Ocean";

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
    ];
  };
}
