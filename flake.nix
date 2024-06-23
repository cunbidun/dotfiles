{
  description = "cunbidun's flake";

  inputs = {
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixpkgs-unstable";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {url = "github:nix-community/home-manager";};
    xremap-flake = {url = "github:xremap/nix-flake";};
    nix-flatpak = {url = "github:gmodena/nix-flatpak";};
    ags = {url = "github:Aylur/ags";};

    nixvim = {url = "github:nix-community/nixvim";};
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};

    ############
    # Hyprland #
    ############
    hyprland = {url = "github:hyprwm/Hyprland/v0.40.0?submodules=1";};
    hypridle = {url = "github:hyprwm/hypridle";};
    pyprland = {url = "github:hyprland-community/pyprland/2.2.20";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    Hyprspace = {
      url = "github:KZDKM/Hyprspace/8049b2794ca19d49320093426677d8c2911e7327";
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
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    nix-flatpak,
    ...
  }: let
    project_root = "${builtins.toString ./.}";
  in {
    darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
      pkgs = import nixpkgs-unstable {
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
      nixos = nixpkgs-unstable.lib.nixosSystem {
        pkgs = import nixpkgs-unstable {
          system = "x86_64-linux";
          overlays = [
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
