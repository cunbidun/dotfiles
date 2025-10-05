{
  pkgs,
  config,
  lib,
  project_root,
  inputs,
  userdata,
  ...
}: let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    inputs = inputs;
    project_root = project_root;
  };
in {
  imports = [
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/tmux.nix"
  ];
  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";
  home.packages = package_config.default_packages;

  home.file = {
    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    TERM = "xterm-256color";
  };

  programs.git = {
    enable = true;
    userName = userdata.name;
    userEmail = userdata.email;
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
