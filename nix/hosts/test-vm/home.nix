{
  inputs,
  pkgs,
  userdata,
  lib,
  ...
}: {
  imports = [
    ../../home-manager/profiles/linux.nix
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/shared/git.nix
  ];

  home.sessionVariables = {
    TERM = "xterm-256color";
  };
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
