{color-scheme, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {enable = true;};
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
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
    initExtra = let
      iterm2-shell-integration = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/gnachman/iTerm2/90626bbb104f1ca1f0ed73aff57edf7608ec5f29/Resources/shell_integration/iterm2_shell_integration.zsh";
        sha256 = "sha256:1xk6kx5kdn5wbqgx2f63vnafhkynlxnlshxrapkwkd9zf2531bqa";
      };
    in ''
      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim
      . $HOME/dotfiles/zsh/zshpath
      . $HOME/dotfiles/zsh/zshtheme
      export BAT_STYLE="plain"
      export BAT_THEME="${color-scheme.bat_theme}"
      export BAT_OPTS="--color always"
      export FZF_DEFAULT_OPTS="${color-scheme.fzf_default_opts}"

      if [[ "$(uname)" == "Darwin" ]]; then
        source ${iterm2-shell-integration}
      fi
    '';
  };
}
