{
  pkgs,
  config,
  lib,
  inputs,
  userdata,
  ...
}: let
  package_config = import ../../home-manager/packages.nix {
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/nvchad.nix
  ];

  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";

  # Only include default packages, no GUI packages
  home.packages = package_config.default_packages;

  home.file = {
    ".config/starship.toml".source = ../../../utilities/starship/starship.toml;
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
