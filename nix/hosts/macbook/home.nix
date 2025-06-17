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
  };
in {
  imports = [
    "${project_root}/nix/home-manager/configs/zsh.nix"
    "${project_root}/nix/home-manager/configs/fzf.nix"
    "${project_root}/nix/home-manager/configs/nvim.nix"
    "${project_root}/nix/home-manager/configs/tmux.nix"
    "${project_root}/nix/home-manager/configs/stylix.nix"
    inputs.stylix.homeManagerModules.stylix
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
    ".local/bin/vscode_extension.py".source = "${project_root}/scripts/vscode_extension.py";
    ".config/starship.toml".source = "${project_root}/utilities/starship/starship.toml";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/nvim";
    ".config/iterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/iterm";
    ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/tmux/.tmux.conf";
    "Library/Application Support/Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/settings.json";
    "Library/Application Support/Code/User/keybindings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/Code/keybindings.json";
    ".zsh/zshenv".source = "${project_root}/zsh/zshenv";
    ".zsh/zshfunctions".source = "${project_root}/zsh/zshfunctions";
    ".zsh/zshvim".source = "${project_root}/zsh/zshvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = userdata.name;
    userEmail = userdata.email;
  };
}
