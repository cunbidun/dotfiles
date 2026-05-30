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
  llm_agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/llm_agent.nix
  ];

  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";
  programs.atuin.enable = true;

  # Only include default packages, no GUI packages
  home.packages =
    package_config.default_packages
    ++ [
      llm_agents.claude-code
    ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    TERM = "xterm-256color";
  };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
