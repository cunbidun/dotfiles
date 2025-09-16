inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "master" inputs.master)
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nur.overlays.default
  (import ./firefox-addons.nix)
  (import ./vim-plugins.nix inputs)
  (import ./vicinae.nix inputs)
  (import ./theme-manager.nix)
]
