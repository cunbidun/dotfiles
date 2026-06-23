{
  inputs,
  lib,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  themeConfigs = import ./shared/theme-configs.nix;
  enabledExtensions = with spicePkgs.extensions; [
    adblockify
    hidePodcasts
  ];

  mkSpotify = spicetify:
    inputs.spicetify-nix.lib.mkSpicetify pkgs {
      inherit enabledExtensions;
      wayland = true;
      theme = spicePkgs.themes.${spicetify.theme};
      colorScheme = spicetify.colorScheme;
    };

  spotifyPackages = lib.mapAttrs' (
    themeName: themeConfig:
      lib.nameValuePair "${themeName}-light" (mkSpotify themeConfig.light.spicetify)
  ) themeConfigs
  // lib.mapAttrs' (
    themeName: themeConfig:
      lib.nameValuePair "${themeName}-dark" (mkSpotify themeConfig.dark.spicetify)
  ) themeConfigs;

  spotifyCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (themeName: spotifyPackage: ''
      ${themeName}) exec ${spotifyPackage}/bin/spotify "$@" ;;
    '') spotifyPackages
  );

  spotify = pkgs.writeShellApplication {
    name = "spotify";
    text = ''
      state_file="$HOME/.local/state/stylix/current-theme-name.txt"
      current_theme="default-dark"

      if [ -r "$state_file" ]; then
        current_theme="$(cat "$state_file")"
      fi

      case "$current_theme" in
      ${spotifyCases}
        *) exec ${spotifyPackages.default-dark}/bin/spotify "$@" ;;
      esac
    '';
  };
in {
  stylix.targets.spicetify.enable = false;

  home.packages = [spotify];

  programs.spicetify = {
    enable = false;
    wayland = true;

    theme = spicePkgs.themes.default;
    colorScheme = "Ocean";

    inherit enabledExtensions;
  };
}
