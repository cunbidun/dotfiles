{ pkgs, config, lib, project_root, inputs, ... }:
let
  package_config = import "${project_root}/nix/home-manager/packages.nix" {
    pkgs = pkgs;
    nixGLWrap = pkg: pkg;
    inputs = inputs;
  };
  color-scheme = import "${project_root}/nix/home-manager/colors/nord.nix";
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "cunbidun";
  home.homeDirectory = "/Users/cunbidun";

  home.packages = package_config.default_packages ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
    shellAliases = {
      cdnote = "cd $HOME/note";
      s = "source $HOME/.zshrc";
      CP = "$HOME/competitive_programming/";
      r = "ranger";
      ls = "exa -la";
      cat = "bat";
      tree = "tree -a";

      # vim;
      vi = "lvim";
      nvim = "lvim";
      vim = "lvim";
    };
    initExtra = ''
      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim
      . $HOME/dotfiles/zsh/zshpath
      . $HOME/dotfiles/zsh/zshtheme
      export BAT_STYLE="plain"
      export BAT_THEME="${color-scheme.bat_theme}"
      export BAT_OPTS="--color always"
      export FZF_DEFAULT_OPTS="${color-scheme.fzf_default_opts}"
    '';
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.git = {
    enable = true;
    userName = "Duy Pham";
    userEmail = "cunbidun@gmail.com";
  };

  #######################
  # lvim configurations #
  #######################
  home.file =
    {
      ".config/lvim/lua".source = "${project_root}/text_editor/lvim/lua";
      ".config/lvim/snippet".source = "${project_root}/text_editor/lvim/snippet";
      ".config/lvim/config.lua".source =
        "${project_root}/text_editor/lvim/config.lua";
      ".config/lvim/cp.vim".source = "${project_root}/text_editor/lvim/cp.vim";
      ".config/lvim/markdown-preview.vim".source =
        "${project_root}/text_editor/lvim/markdown-preview.vim";
    };
}
