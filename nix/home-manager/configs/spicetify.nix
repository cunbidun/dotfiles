{
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  enabledExtensions = with spicePkgs.extensions; [
    adblockify
    hidePodcasts
  ];
in {
  stylix.targets.spicetify.enable = false;

  programs.spicetify = {
    enable = true;
    wayland = true;

    theme = spicePkgs.themes.default;
    colorScheme = "Ocean";

    inherit enabledExtensions;
  };
}
