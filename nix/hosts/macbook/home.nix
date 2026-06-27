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
    ../../home-manager/profiles/darwin.nix
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/tmux
    ../../home-manager/configs/vscode.nix
    ../../home-manager/configs/shared/git.nix
    inputs.self.homeManagerModules.theme-manager
    inputs.mac-app-util.homeManagerModules.default
  ];
  home.packages = package_config.default_packages ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "iterm2";
  };

  home.file = {
    ".config/iterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/iterm";
  };

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
