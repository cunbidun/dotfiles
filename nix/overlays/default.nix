inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "master" inputs.master)
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nix4vscode.overlays.default
  inputs.nur.overlays.default
  (import ./firefox-addons.nix)
  (import ./vim-plugins.nix inputs)
  (import ./theme-manager.nix)
  (import ./everforest-themes.nix)
]
