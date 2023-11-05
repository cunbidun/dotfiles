{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    pypr.url = "github:hyprland-community/pyprland";
  };

  outputs = { nixpkgsUnstable, home-manager, pypr, ... }:
    let system = "x86_64-linux";
    in {
      homeConfigurations.cunbidun = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgsUnstable {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit pypr; };
      };
    };
}
