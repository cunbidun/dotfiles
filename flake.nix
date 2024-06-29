{
  description = "cunbidun's flake";

  nixConfig = {
    extra-substituters = ["https://hyprland.cachix.org"];
    extra-trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  inputs = {
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixpkgs-unstable";};
    nixpkgs-stable = {url = "github:nixos/nixpkgs/nixos-23.11";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {url = "github:nix-community/home-manager";};
    xremap-flake = {url = "github:xremap/nix-flake";};
    nix-flatpak = {url = "github:gmodena/nix-flatpak";};
    ags = {url = "github:Aylur/ags";};

    nixvim = {url = "github:nix-community/nixvim";};
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};

    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "git+https://github.com/hyprwm/Hyprland?submodules=1";};
    hypridle = {url = "github:hyprwm/hypridle";};
    pyprland = {url = "github:hyprland-community/pyprland/2.2.20";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    Hyprspace = {
      url = "github:clague/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    hyprfocus = {
      url = "github:pyt0xic/hyprfocus";
      inputs.hyprland.follows = "hyprland";
    };
    hycov = {
      url = "github:DreamMaoMao/hycov";
      inputs.hyprland.follows = "hyprland";
    };

    # +-------------+
    # | nvim plugin |
    # +-------------+
    nvim-plugin-easypick = {
      url = "github:axkirillov/easypick.nvim";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs-unstable,
    nixpkgs-stable,
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
            lunarvim = nixpkgs-stable.legacyPackages.${prev.system}.lunarvim;
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
          (mkHomeManagerModule "${project_root}/nix/hosts/noxos/home.nix")
          {nixpkgs.config.permittedInsecurePackages = ["electron-25.9.0"];}
        ];
      };
    };
  };
}
