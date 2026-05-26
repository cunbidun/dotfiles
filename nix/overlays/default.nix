inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nix4vscode.overlays.default
  inputs.claude-desktop.overlays.default
  (import ./theme-manager.nix)
  (import ./mac-default-browser.nix inputs)
]
