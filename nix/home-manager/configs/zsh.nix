{pkgs, ...}: {
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
      ls = "exa -la";
      cat = "bat";
      tree = "tree -a";
    };
    initExtra = ''
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080'

      . $HOME/dotfiles/zsh/zshenv
      . $HOME/dotfiles/zsh/zshfunctions
      . $HOME/dotfiles/zsh/zshvim

      # adding important bin to bash
      export PATH=$PATH:$HOME/.scripts/bin
      export PATH=$PATH:$HOME/.local/bin
      export PATH=$PATH:$HOME/.cargo/bin

      [ -d "/snap/bin" ] && export PATH=$PATH:/snap/bin
      export BAT_STYLE="plain"

      eval "$(starship init zsh)"
    '';
  };
}
