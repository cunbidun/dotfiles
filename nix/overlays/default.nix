inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nix4vscode.overlays.default
  (import ./theme-manager.nix inputs)
  (import ./mac-default-browser.nix inputs)
]
