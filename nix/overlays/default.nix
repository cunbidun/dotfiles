inputs: let
  mkSubPkgsOverlay = import ./mkSubPkgsOverlay.nix;
in [
  (mkSubPkgsOverlay "nixpkgs-master" inputs.nixpkgs-master)
  (mkSubPkgsOverlay "nixpkgs-stable" inputs.nixpkgs-stable)
  inputs.nix4vscode.overlays.default
  # Silence deprecated pkgs.system / stdenv.system alias (use stdenv.hostPlatform.system instead)
  (_: super: {
    system = super.stdenv.hostPlatform.system;
    stdenv = super.stdenv // { system = super.stdenv.hostPlatform.system; };
  })
  (import ./theme-manager.nix)
  (import ./everforest-themes.nix)
  (import ./mac-default-browser.nix inputs)
]
