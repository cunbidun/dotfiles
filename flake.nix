{
  description = "cunbidun's dotfiles";

  inputs = {
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {url = "github:nix-community/home-manager";};
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};

    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "github:hyprwm/Hyprland/?submodules=1";};
    hypridle = {url = "github:hyprwm/hypridle";};
    pyprland = {url = "github:hyprland-community/pyprland";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    hyprcursor-phinger = {url = "github:jappie3/hyprcursor-phinger";};
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.hyprland.follows = "hyprland";
    };
    hyprfocus = {
      url = "github:cunbidun/hyprfocus";
      inputs.hyprland.follows = "hyprland";
    };
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };

    # +--------+
    # | Others |
    # +--------+
    yazi = {url = "github:sxyazi/yazi/v25.4.8";};
    stylix = {url = "github:nix-community/stylix";};
    spicetify-nix = {url = "github:Gerg-L/spicetify-nix";};

    nix-monitored = {
      url = "github:ners/nix-monitored";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    mac-app-util.url = "github:hraban/mac-app-util";
    nur.url = "github:nix-community/nur";

    # +----------------+
    # | Neovim plugins |
    # +----------------+
    auto-dark-mode-nvim = {
      url = "github:f-person/auto-dark-mode.nvim";
      flake = false;
    };
    copilot-lua = {
      url = "github:zbirenbaum/copilot.lua";
      flake = false;
    };
    blink-copilot = {
      url = "github:fang2hou/blink-copilot";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    ...
  }: let
    project_root = ./.;
    userdata = import ./userdata.nix;
    mkPkgs = system:
      import nixpkgs-unstable {
        inherit system;
        overlays = [
          inputs.nur.overlays.default
          (import "${project_root}/nix/overlays/firefox-addons.nix")
          (import "${project_root}/nix/overlays/vim-plugins.nix" inputs)
        ];
        config.allowUnfree = true;
      };

    mkHomeManagerModule = configPath: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${userdata.username} = import configPath;
        extraSpecialArgs = {
          inherit project_root inputs;
          userdata = userdata;
        };
      };
    };

    mkDarwinSystem = {
      system,
      stateVersionNum,
    }:
      nix-darwin.lib.darwinSystem {
        pkgs = mkPkgs system;
        specialArgs = {
          inherit inputs userdata;
          stateVersion = stateVersionNum;
        };
        modules = [
          inputs.mac-app-util.darwinModules.default
          ./nix/hosts/macbook/configuration.nix
          home-manager.darwinModules.home-manager
          (mkHomeManagerModule "${project_root}/nix/hosts/macbook/home.nix")
        ];
      };

    mkNixosHost = {
      system,
      hostPath,
      homePath,
    }:
      nixpkgs-unstable.lib.nixosSystem {
        pkgs = mkPkgs system;
        specialArgs = {
          inherit inputs userdata;
        };
        modules = [
          hostPath
          home-manager.nixosModules.home-manager
          (mkHomeManagerModule homePath)
        ];
      };
  in {
    # -----------------------#
    # macbook configurations #
    # -----------------------#
    darwinConfigurations = {
      "macbook-m1" = mkDarwinSystem {
        system = "aarch64-darwin";
        stateVersionNum = 4;
      };
      "macbook-intel" = mkDarwinSystem {
        system = "x86_64-darwin";
        stateVersionNum = 5;
      };
    };

    # -----------------------#
    #  nixos configurations  #
    # -----------------------#
    nixosConfigurations = {
      nixos = mkNixosHost {
        system = "x86_64-linux";
        hostPath = ./nix/hosts/nixos/configuration.nix;
        homePath = "${project_root}/nix/hosts/nixos/home.nix";
      };
    };
  };
}
