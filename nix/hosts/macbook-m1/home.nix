{
  pkgs,
  config,
  lib,
  project_root,
  inputs,
  ...
}: let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    inputs.xremap-flake.homeManagerModules.default
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/fzf.nix"
    "${project_root}/nix/home-manager/configs/nvim.nix"
    "${project_root}/nix/home-manager/configs/stylix.nix"
    "${project_root}/nix/home-manager/configs/vscode.nix"
    inputs.stylix.homeManagerModules.stylix
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/Users/cunbidun";

  home.packages = package_config.default_packages ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "iterm2";
  };

  home.file = {
    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };
}
