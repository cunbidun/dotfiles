{
  description = "cunbidun's flake";

   inputs = {
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    # pypr.url = "github:hyprland-community/pyprland#ac6bba1";
    pypr = {
      type = "github";
      owner = "hyprland-community";
      repo = "pyprland";
    };
  };

  outputs = { nixpkgsUnstable, home-manager, pypr, ... }:
    let system = "x86_64-linux";
    in {
      homeConfigurations.cunbidun = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgsUnstable {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ ./nix/home-manager/home.nix ];
        extraSpecialArgs = { inherit pypr; };
      };
    };
}
