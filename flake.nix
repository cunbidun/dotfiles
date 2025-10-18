{
  description = "cunbidun's dotfiles";
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nixos-raspberrypi.cachix.org"
      "https://hyprland.cachix.org"
      "https://yazi.cachix.org"
      "https://winapps.cachix.org/"
      "https://vicinae.cachix.org"
      "https://codex-cli.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "codex-cli.cachix.org-1:BH31Jb2xSzV+9BFgVfR9j7TDW3L8CSMziFdfLrKEKIk="
    ];
    connect-timeout = 5;
  };

  inputs = {
    master.url = "github:nixos/nixpkgs?ref=master";
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-stable = {url = "github:nixos/nixpkgs/nixos-25.05";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {url = "github:nix-community/home-manager";};
    apple-fonts = {url = "github:Lyndeno/apple-fonts.nix";};
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "github:hyprwm/Hyprland/v0.51.1/?submodules=1";};
    pyprland = {url = "github:hyprland-community/pyprland";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    hyprcursor-phinger = {url = "github:jappie3/hyprcursor-phinger";};
    xremap-flake = {
      url = "github:xremap/nix-flake/226fcadfe1d810a89ce318f6a304df3caf7f9cd7";
      inputs.hyprland.follows = "hyprland";
    };
    hyprfocus = {
      url = "github:daxisunder/hyprfocus";
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
    hyprpanel = {
      url = "github:cunbidun/HyprPanel";
      # url = "path:/home/cunbidun/.tmp/HyprPanel";
    };
    nur.url = "github:nix-community/nur";

    nix-monitored = {
      url = "github:ners/nix-monitored";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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

    # +-- MacOS specific --+
    mac-app-util.url = "github:hraban/mac-app-util";

    # +-- Raspberry Pi --+
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    home-manager-rpi5 = {url = "github:nix-community/home-manager/release-25.05";};

    codex-nix = {
      url = "github:sadjow/codex-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae/v0.14.5";
    };

    # +-- Windows interop --+
    winboat = {
      # TODO: change to master branch after https://github.com/TibixDev/winboat/pull/281 get merged
      url = "github:Rexcrazy804/winboat?ref=fix-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    nixpkgs-unstable,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    userdata = import ./userdata.nix;
    mkPkgs = system:
      import nixpkgs-unstable {
        inherit system;
        overlays = import ./nix/overlays inputs;
        config.allowUnfree = true;
      };

    mkHomeManagerModule = configPath: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${userdata.username} = import configPath;
        extraSpecialArgs = {
          inherit inputs;
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
          (mkHomeManagerModule ./nix/hosts/macbook/home.nix)
        ];
      };

    mkNixosHost = {
      system,
      hostPath,
      homePath,
      diskoPath,
    }:
      nixpkgs-unstable.lib.nixosSystem {
        pkgs = mkPkgs system;
        specialArgs = {
          inherit inputs userdata;
        };
        modules = [
          inputs.disko.nixosModules.disko
          diskoPath
          hostPath
          home-manager.nixosModules.home-manager
          (mkHomeManagerModule homePath)
        ];
      };
  in {
    # for running commands like `nix eval .#inputs.hyprland.packages.x86_64-linux.hyprland`
    inputs = inputs;

    # Home Manager modules
    homeManagerModules = {
      theme-manager = import ./nix/theme-manager/hm-module.nix;
    };

    # -----------------------#
    # macbook configurations #
    # -----------------------#
    darwinConfigurations = {
      "macbook-m1" = mkDarwinSystem {
        system = "aarch64-darwin";
        stateVersionNum = 4;
      };
    };

    # -----------------------#
    #  nixos configurations  #
    # -----------------------#
    nixosConfigurations = {
      nixos = mkNixosHost {
        system = "x86_64-linux";
        hostPath = ./nix/hosts/nixos/configuration.nix;
        homePath = ./nix/hosts/nixos/home.nix;
        diskoPath = ./nix/hosts/nixos/disko.nix;
      };

      rpi5 = inputs.nixos-raspberrypi.lib.nixosSystemFull {
        specialArgs = inputs // {inherit userdata;};
        trustCaches = true;
        modules = [
          ({nixos-raspberrypi, ...}: {
            imports = with nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              raspberry-pi-5.display-vc4
            ];
          })
          inputs.disko.nixosModules.disko
          ./nix/hosts/rpi/hardware-configuration.nix
          ./nix/hosts/rpi/configuration.nix
          inputs.home-manager-rpi5.nixosModules.home-manager
          (mkHomeManagerModule ./nix/hosts/rpi/home.nix)
          ({...}: {
            nixpkgs.overlays =
              import ./nix/overlays inputs
              ++ [
                (final: prev: {
                  pythonPackagesExtensions =
                    prev.pythonPackagesExtensions
                    ++ [
                      (pythonFinal: pythonPrev: {
                        # Override markdown-it-py for all Python versions
                        markdown-it-py = pythonPrev."markdown-it-py".overridePythonAttrs (old: {
                          doCheck = false;
                          doInstallCheck = false;
                        });
                      })
                    ];
                })
              ];
          })
        ];
      };
    };

    # -----------------------#
    #     runnable apps      #
    # -----------------------#
    apps = let
      forAllSystems = f:
        builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        }) ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"]);
    in
      forAllSystems (system: let
        pkgs = mkPkgs system;
        themeManager = pkgs.theme-manager;
      in {
        theme-manager = {
          type = "app";
          program = "${themeManager}/bin/theme-manager";
        };
        themectl = {
          type = "app";
          program = "${themeManager}/bin/themectl";
        };
      });
  };
}
