# Helper function to create overlays for different nixpkgs versions
# This allows us to use pkgs.master.vscode and pkgs.nixpkgs-stable.vscode
targetName: input: (self: super: {
  "${targetName}" =
    super."${targetName}" or {}
    // import input {
      inherit (super) system;
      config = super.config;
    };
})
