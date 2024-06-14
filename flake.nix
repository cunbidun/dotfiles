{
  description = "cunbidun's flake";

  inputs = {
    nixpkgsUnstable = {url = "github:nixos/nixpkgs/nixpkgs-unstable";};
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    nixgl = {url = "github:guibou/nixGL";};
    xremap-flake = {url = "github:xremap/nix-flake";};
    nix-flatpak = {url = "github:gmodena/nix-flatpak";};
    ags = {url = "github:Aylur/ags";};

    nixvim = {
      url = "github:nix-community/nixvim/b113bc69ea5c04c37020a63afa687abfb2d43474";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    apple-fonts = {url = "github:cunbidun/apple-fonts.nix";};

    ############
    # Hyprland #
    ############
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.40.0?submodules=1";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
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

    ###############
    # nvim plugin #
    ###############
    nvim-plugin-easypick = {
      url = "github:axkirillov/easypick.nvim";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgsUnstable,
    nix-darwin,
    home-manager,
    nixgl,
    nix-flatpak,
    ...
  }: let
    project_root = "${builtins.toString ./.}";
  in {
    darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
      pkgs = import nixpkgsUnstable {
        system = "aarch64-darwin";
        config = {allowUnfree = true;};
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
          overlays = [
            nixgl.overlay
            # add easypick.nvim plugin
            (final: prev: {
              vimPlugins =
                prev.vimPlugins
                // {
                  nvim-plugin-easypick = prev.vimUtils.buildVimPlugin {
                    name = "easypick.nvim";
                    src = inputs.nvim-plugin-easypick;
                  };
                };
            })
          ];
          config = {
            allowUnfree = true;
            permittedInsecurePackages = ["electron-25.9.0"];
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
