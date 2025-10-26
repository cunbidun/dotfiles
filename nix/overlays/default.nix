inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "nixpkgs-master" inputs.nixpkgs-master)
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nix4vscode.overlays.default
  (import ./vim-plugins.nix inputs)
  (import ./theme-manager.nix)
  (import ./everforest-themes.nix)
]
