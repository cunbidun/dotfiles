{ config, pkgs, ... }:

let
  pkgsUnstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/home/cunbidun";
  home.packages = [                               
    pkgs.htop
    pkgs.neovim
    pkgs.git
    pkgs.zsh
    pkgs.neofetch
    pkgs.fzf
    pkgsUnstable._1password-gui
    pkgsUnstable._1password
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
