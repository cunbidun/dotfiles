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
    yazi.url = "github:sxyazi/yazi/v25.4.8";

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
    project_root = "${builtins.toString ./.}";
    userdata = import ./userdata.nix;
    mkPkgs = system:
      import nixpkgs-unstable {
        inherit system;
        overlays = [
          inputs.nur.overlays.default
          (
            final: prev: {
              nur.repos.rycee.firefox-addons =
                prev.nur.repos.rycee.firefox-addons
                // {
                  carrot = prev.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon rec {
                    pname = "carrot";
                    version = "0.6.8";
                    url = "https://addons.mozilla.org/firefox/downloads/file/4450645/carrot-${version}.xpi";
                    sha256 = "sha256-4QXp97JyqBBHcZbCReEzKCltTBc8WShETjVXYjq2WZ0";
                    addonId = "{f0eeb71a-e5d6-48e6-a818-568a6bef1bc0}";
                    meta = {
                    };
                  };
                };
              # Add the home-manager overlay to the Nixpkgs overlays.
            }
          )

          (final: prev: {
            vimPlugins =
              prev.vimPlugins
              // {
                auto-dark-mode-nvim = prev.vimUtils.buildVimPlugin {
                  pname = "auto-dark-mode.nvim";
                  src = inputs.auto-dark-mode-nvim;
                  version = inputs.auto-dark-mode-nvim.shortRev;
                };
                copilot-lua = prev.vimUtils.buildVimPlugin {
                  pname = "copilot-lua";
                  src = inputs.copilot-lua;
                  version = inputs.copilot-lua.shortRev;
                };
                blink-copilot = prev.vimUtils.buildVimPlugin {
                  pname = "blink-copilot";
                  src = inputs.blink-copilot;
                  version = inputs.blink-copilot.shortRev;
                };
              };
          })
        ];
        config.allowUnfree = true;
      };
    mkHomeManagerModule = configPath: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.${userdata.username} = import configPath;
        extraSpecialArgs = {
          inherit project_root inputs;
          userdata = userdata;
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
        userdata = userdata;
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
        stateVersion = 5;
        userdata = userdata;
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
          userdata = userdata;
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
