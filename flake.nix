{
  description = "cunbidun's flake";

  inputs = {
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-stable = {url = "github:nixos/nixpkgs/nixos-24.05";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {
      url = "github:nix-community/home-manager";
    };
    xremap-flake = {url = "github:xremap/nix-flake";};
    nix-flatpak = {url = "github:gmodena/nix-flatpak";};
    ags = {url = "github:Aylur/ags";};

    nixvim = {
      url = "github:nix-community/nixvim";
    };
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};

    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "github:hyprwm/Hyprland/v0.46.2?submodules=1";};
    hypridle = {url = "github:hyprwm/hypridle";};
    pyprland = {url = "github:hyprland-community/pyprland";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    hyprfocus = {
      url = "github:pyt0xic/hyprfocus/e7d9ee3c470b194fe16179ff2f16fc4233e928ef";
      inputs.hyprland.follows = "hyprland";
    };

    hyprcursor-phinger.url = "github:jappie3/hyprcursor-phinger";
    stylix.url = "github:danth/stylix";

    # +-------------+
    # | nvim plugin |
    # +-------------+
    nvim-plugin-easypick = {
      url = "github:axkirillov/easypick.nvim";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    mkPkgs = system:
      import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
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
      };
    mkHomeManagerModule = configPath: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.cunbidun = import configPath;
        extraSpecialArgs = {inherit project_root inputs;};
      };
    };
  in {
    ##########################
    # macbook configurations #
    ##########################
    # nix --log-format internal-json run nix-darwin -- switch --flake ~/dotfiles#macbook-m1 |& nom
    darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
      pkgs = mkPkgs "aarch64-darwin";
      modules = [
        ./nix/hosts/macbook-m1/configuration.nix
        home-manager.darwinModules.home-manager
        (mkHomeManagerModule "${project_root}/nix/hosts/macbook-m1/home.nix")
      ];
    };

    #######################
    # nixos configuration #
    #######################
    nixosConfigurations = {
      # build with sudo nixos-rebuild switch --flake ~/dotfiles#nixos
      nixos = nixpkgs-unstable.lib.nixosSystem {
        pkgs = mkPkgs "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./nix/hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          (mkHomeManagerModule "${project_root}/nix/hosts/nixos/home.nix")
        ];
      };
    };
  };
}
