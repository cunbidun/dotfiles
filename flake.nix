{
  description = "cunbidun's flake";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixgl.url = "github:guibou/nixGL";
    xremap-flake.url = "github:xremap/nix-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    ags.url = "github:Aylur/ags";
    stylix.url = "github:danth/stylix";

    ############
    # Hyprland #
    ############
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.40.0?submodules=1";
    };
    pyprland = {
      url = "github:hyprland-community/pyprland/2.2.20";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
    };
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    hyprfocus = {
      url = "github:pyt0xic/hyprfocus";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs =
    inputs@{ nixpkgs-unstable
    , nixpkgs-stable
    , nix-darwin
    , home-manager
    , nixgl
    , nix-flatpak
    , ...
    }:
    let project_root = "${builtins.toString ./.}";

    in {
      darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgs-unstable {
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
        nixos = nixpkgs-unstable.lib.nixosSystem {
          pkgs = import nixpkgs-unstable {
            system = "x86_64-linux";
            overlays = [
              nixgl.overlay
              # temporary overlay the older version of lvim 
              (final: prev: {
                lunarvim = nixpkgs-stable.legacyPackages.${prev.system}.lunarvim;
              })
            ];
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
            inputs.stylix.nixosModules.stylix
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
