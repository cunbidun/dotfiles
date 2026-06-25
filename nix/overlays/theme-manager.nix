inputs: final: prev: {
  theme-manager = prev.callPackage ../theme-manager/package.nix {
    hyprland = inputs.hyprland.packages.${final.stdenv.hostPlatform.system}.hyprland;
    vicinae = inputs.vicinae.packages.${final.stdenv.hostPlatform.system}.default;
  };
}
