{ color-scheme, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
    };
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
}
