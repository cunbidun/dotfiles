{
  inputs,
  pkgs,
  userdata,
  lib,
  ...
}: {
  imports = [
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/shared/git.nix
  ];

  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";

  programs.home-manager.enable = true;

  # vi-mode causes key tripling in some terminals; not needed for a test VM
  programs.zsh.plugins = lib.mkForce [];
  programs.atuin.enable = true;
  programs.zoxide.enable = true;
  programs.bat.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ServerAliveInterval = 20;
        ServerAliveCountMax = 3;
        TCPKeepAlive = "yes";
      };
    };
  };

  home.stateVersion = "25.05";
}
