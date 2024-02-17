{
  description = "cunbidun's flake";

  inputs = {
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
    nixgl.url = "github:guibou/nixGL";
    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs = inputs@{ nixpkgsUnstable, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      project_root = "${builtins.toString ./.}";
    in {
      homeConfigurations.cunbidun = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgsUnstable {
          inherit system;
          overlays = [ nixgl.overlay ];
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-25.9.0" ];
          };
        };
        modules = [
          ./nix/home-manager/home.nix
          inputs.xremap-flake.homeManagerModules.default
          {
            services.xremap = {
              withWlroots = true;
              watch = true;
              yamlConfig = ''
                modmap:
                  - name: Global
                    application:
                      not: [Alacritty, steam, dota1, qemu-system-x86_64, qemu, Qemu-system-x86_64]
                    remap:
                      Alt_L: Ctrl_L 
              '';
            };
          }
        ];
        extraSpecialArgs = {
          inherit project_root;
          inherit inputs;
        };
      };
    };
}
