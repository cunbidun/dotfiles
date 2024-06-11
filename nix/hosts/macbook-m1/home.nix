{ pkgs, config, lib, project_root, inputs, ... }:
let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    nixGLWrap = pkg: pkg;
    inputs = inputs;
  };
  color-scheme = import "${project_root}/nix/home-manager/colors/vscode-dark.nix";
in
{
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    inputs.ags.homeManagerModules.default
    (import "${project_root}/nix/home-manager/configs/zsh.nix" {
      color-scheme = color-scheme;
    })
    "${project_root}/nix/home-manager/configs/fzf.nix"
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/Users/cunbidun";

  home.packages = package_config.default_packages
    ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };
}
