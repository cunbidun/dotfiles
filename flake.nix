{
  description = "cunbidun's flake";

   inputs = {
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
  };

  outputs = { nixpkgsUnstable, home-manager, ... }:
    let 
      system = "x86_64-linux";
      project_root = "${builtins.toString ./.}";
    in {
      homeConfigurations.cunbidun = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgsUnstable {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "electron-25.9.0"
            ];
          };
        };
        modules = [ ./nix/home-manager/home.nix ];
        extraSpecialArgs = { inherit project_root; };
      };
    };
}
