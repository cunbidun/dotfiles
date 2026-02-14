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
      "https://noel.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "winapps.cachix.org-1:HI82jWrXZsQRar/PChgIx1unmuEsiQMQq+zt05CD36g="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "codex-cli.cachix.org-1:BH31Jb2xSzV+9BFgVfR9j7TDW3L8CSMziFdfLrKEKIk="
      "noel.cachix.org-1:pQHbMJOB5h5VqYi3RV0Vv0EaeHfxARxgOhE9j013XwQ="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixpkgs-master = {url = "github:nixos/nixpkgs";};
    nixpkgs-unstable = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nixpkgs-stable = {url = "github:nixos/nixpkgs/nixos-25.05";};
    nix-darwin = {url = "github:LnL7/nix-darwin";};
    home-manager = {url = "github:nix-community/home-manager";};
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # +----------+
    # | Hyprland |
    # +----------+
    hyprland = {url = "github:hyprwm/Hyprland/v0.53.1/?submodules=1";};
    pyprland = {url = "github:hyprland-community/pyprland";};
    hyprland-contrib = {url = "github:hyprwm/contrib";};
    hyprcursor-phinger = {url = "github:jappie3/hyprcursor-phinger";};
    xremap-flake = {
      url = "github:xremap/nix-flake";
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
    yazi = {url = "github:sxyazi/yazi/v26.1.4";};
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
    yazi-restore = {
      url = "github:boydaihungst/restore.yazi";
      flake = false;
    };
    yazi-bunny = {
      url = "github:stelcodes/bunny.yazi";
      flake = false;
    };
    stylix = {url = "github:nix-community/stylix";};
    hyprpanel = {
      url = "github:cunbidun/HyprPanel";
    };

    nix-monitored = {
      url = "github:ners/nix-monitored";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    vscode-insiders = {
      url = "github:auguwu/vscode-insiders-nix";
      inputs.nixpkgs.follows = "nixpkgs-master";
    };

    # +-- MacOS specific --+
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-default-browser = {
      url = "github:macadmins/default-browser/v1.0.18";
      flake = false;
    };

    # +-- Raspberry Pi --+
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    home-manager-rpi5 = {url = "github:nix-community/home-manager/release-25.05";};

    codex-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae/v0.18.3";
    };
    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
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
        backupFileExtension = "bak";
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
          inputs.stylix.nixosModules.stylix
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

      home-server = mkNixosHost {
        system = "x86_64-linux";
        hostPath = ./nix/hosts/home-server/configuration.nix;
        homePath = ./nix/hosts/home-server/home.nix;
        diskoPath = ./nix/hosts/home-server/disko.nix;
      };

      minimal = nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = mkPkgs "x86_64-linux";
        specialArgs = {
          inherit inputs userdata;
        };
        modules = [
          ./nix/hosts/minimal/configuration.nix
        ];
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
        flake-input-versions = let
          pythonWithDeps = pkgs.python3.withPackages (ps: with ps; [texttable]);
          script = pkgs.writeShellScriptBin "flake-input-versions" ''
            exec ${pythonWithDeps}/bin/python3 ${./scripts/flake_input_versions.py} "$@"
          '';
        in {
          type = "app";
          program = "${script}/bin/flake-input-versions";
        };
        precommit = let
          script = pkgs.writeShellScriptBin "precommit-run" ''
            cd "$(git rev-parse --show-toplevel)"
            ${pkgs.pre-commit}/bin/pre-commit "$@"
          '';
        in {
          type = "app";
          program = "${script}/bin/precommit-run";
        };
        switch = let
          pythonWithDeps = pkgs.python3.withPackages (ps: with ps; []);
          script = pkgs.writeShellScriptBin "nix-switch" ''
            exec ${pythonWithDeps}/bin/python3 ${./scripts/switch.py} "$@"
          '';
        in {
          type = "app";
          program = "${script}/bin/nix-switch";
        };
      });
  };
}
