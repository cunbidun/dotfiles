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
    ../../home-manager/profiles/linux.nix
    inputs.sops-nix.homeManagerModules.sops
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/llm_agent.nix
    ../../home-manager/configs/user-secrets.nix
    ../../home-manager/configs/yazi.nix
  ];

  # Only include default packages, no GUI packages
  home.packages = package_config.default_packages;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
  };

  home.stateVersion = "25.05";

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "opencode web interface";
      After = ["network.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
      }/bin/opencode web --port 10300 --hostname 0.0.0.0";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
