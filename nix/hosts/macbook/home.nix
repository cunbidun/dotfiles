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
    ../../home-manager/configs/nvchad.nix
    ../../home-manager/configs/tmux.nix
    ../../home-manager/configs/vscode.nix
    inputs.self.homeManagerModules.theme-manager
    inputs.stylix.homeModules.stylix
    inputs.mac-app-util.homeManagerModules.default
  ];
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = userdata.username;
  home.homeDirectory = "/Users/${userdata.username}";

  home.packages = package_config.default_packages ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "iterm2";
  };

  home.file = {
    ".config/starship.toml".source = ../../../utilities/starship/starship.toml;
    ".config/iterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/iterm";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userdata.name;
        email = userdata.email;
      };
    };
  };

  home.activation.setDefaultBrowser = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure Chrome is the default handler for HTTP/HTTPS
    ${pkgs.mac-default-browser}/bin/default-browser --identifier com.google.chrome
  '';
}
