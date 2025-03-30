{
  description = "cunbidun's dotfiles";

  inputs = {
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-stable = {url = "github:nixos/nixpkgs/nixos-24.11";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {
      url = "github:nix-community/home-manager";
    };
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.hyprland.follows = "hyprland";
    };
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};

    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "github:hyprwm/Hyprland/v0.48.1?submodules=1";};
    hypridle = {url = "github:hyprwm/hypridle";};
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    pyprland = {url = "github:hyprland-community/pyprland";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    hyprcursor-phinger = {url = "github:jappie3/hyprcursor-phinger";};
    hyprfocus = {
      url = "github:MartinLoeper/hyprfocus";
      inputs.hyprland.follows = "hyprland";
    };

    # +--------+
    # | Others |
    # +--------+
    stylix = {url = "github:danth/stylix";};
    spicetify-nix = {url = "github:Gerg-L/spicetify-nix";};

    mac-app-util.url = "github:hraban/mac-app-util";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs @ {
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    ...
  }: let
    project_root = "${builtins.toString ./.}";
    userdata = import ./userdata.nix;
    username = userdata.username;
    mkPkgs = system:
      import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    mkHomeManagerModule = configPath: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.cunbidun = import configPath;
        extraSpecialArgs = {
          inherit project_root inputs;
          username = username;
        };
      };
    };
  in {
    ##########################
    # macbook configurations #
    ##########################
    # nix --log-format internal-json run nix-darwin -- switch --flake ~/dotfiles#macbook-m1 |& nom
    darwinConfigurations."macbook-m1" = nix-darwin.lib.darwinSystem {
      pkgs = mkPkgs "aarch64-darwin";
      specialArgs = {
        inherit inputs;
        stateVersion = 4;
        username = username;
      };
      modules = [
        inputs.mac-app-util.darwinModules.default
        ./nix/hosts/macbook/configuration.nix
        home-manager.darwinModules.home-manager
        (mkHomeManagerModule "${project_root}/nix/hosts/macbook/home.nix")
      ];
    };

    ##########################
    # macbook configurations #
    ##########################
    # nix --log-format internal-json run nix-darwin -- switch --flake ~/dotfiles#macbook-intel |& nom
    darwinConfigurations."macbook-intel" = nix-darwin.lib.darwinSystem {
      pkgs = mkPkgs "x86_64-darwin";
      specialArgs = {
        inherit inputs;
        username = username;
        stateVersion = 5;
      };
      modules = [
        inputs.mac-app-util.darwinModules.default
        ./nix/hosts/macbook/configuration.nix
        home-manager.darwinModules.home-manager
        (mkHomeManagerModule "${project_root}/nix/hosts/macbook/home.nix")
      ];
    };

    #######################
    # nixos configuration #
    #######################
    nixosConfigurations = {
      # build with sudo nixos-rebuild switch --flake ~/dotfiles#nixos
      nixos = nixpkgs-unstable.lib.nixosSystem {
        pkgs = mkPkgs "x86_64-linux";
        specialArgs = {
          inherit inputs;
          username = username;
        };
        modules = [
          ./nix/hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          (mkHomeManagerModule "${project_root}/nix/hosts/nixos/home.nix")
        ];
      };
    };
  };
}
