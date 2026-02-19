inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  (import inputs.vscode-insiders)
  inputs.nix4vscode.overlays.default
  (import ./theme-manager.nix)
  (import ./mac-default-browser.nix inputs)
]
