{
  description = "cunbidun's flake";

  inputs = {
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    nixgl.url = "github:guibou/nixGL";
    xremap-flake.url = "github:xremap/nix-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    ags.url = "github:Aylur/ags";

    ############
    # Hyprland #
    ############
    hyprland = {
      url = github:hyprwm/Hyprland;
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.hyprland.follows = "hyprland";
    };
    Hyprspace = {
      url = github:KZDKM/Hyprspace;
      inputs.hyprland.follows = "hyprland";
    };
    hyprfocus = {
      url = "github:pyt0xic/hyprfocus"; # Not the official git repository 
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs =
    inputs@{ nixpkgsUnstable
    , nix-darwin
    , home-manager
    , nixgl
    , nix-flatpak
    , ...
    }:
    let project_root = "${builtins.toString ./.}";
    in {
      darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgsUnstable {
          system = "aarch64-darwin";
          config = { allowUnfree = true; };
        };
        modules = [
          ./nix/hosts/macbook-m1/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cunbidun =
              import "${project_root}/nix/hosts/macbook-m1/home.nix";
            home-manager.extraSpecialArgs = {
              inherit project_root;
              inherit inputs;
            };
          }
        ];
      };
      nixosConfigurations = {
        # build with sudo nixos-rebuild switch --flake ~/dotfiles#nixos
        nixos = nixpkgsUnstable.lib.nixosSystem {
          pkgs = import nixpkgsUnstable {
            system = "x86_64-linux";
            overlays = [ nixgl.overlay ];
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [ "electron-25.9.0" ];
            };
          };
          specialArgs = {
            inherit inputs;
          };
          modules = [
            nix-flatpak.nixosModules.nix-flatpak
            ./nix/hosts/nixos/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.cunbidun = import "${project_root}/nix/hosts/nixos/home.nix";
              home-manager.extraSpecialArgs = {
                inherit project_root;
                inherit inputs;
              };
            }
          ];
        };
      };
    };
}
