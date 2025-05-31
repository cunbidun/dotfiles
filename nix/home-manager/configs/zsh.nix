{
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestion = {
      enable = true;
      highlight = "fg=#808080";
    };

    syntaxHighlighting = {
      enable = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
    };

    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];

    shellAliases = {
      cdnote = "cd $HOME/note";
      s = "source $HOME/.zshrc";
      CP = "cd $HOME/competitive_programming/";
      ls = "exa -la";
      cat = "bat";
      tree = "tree -a";
    };

    sessionVariables = {
      ZVM_INIT_MODE = "sourcing";
    };

    initContent = ''
      ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -d "/snap/bin" ] && export PATH=$PATH:/snap/bin

      if [ ! -d "/etc/nixos" ]; then
        export CONDA_CHANGEPS1=false
        export PATH=/etc/profiles/per-user/$USER/bin:$PATH

        if [ "$(uname)" = "Darwin" ]; then
          export CONDA_ROOT="/Users/$USER/miniconda3"
        else
          export CONDA_ROOT="/home/$USER/miniconda3"
        fi

        # if it's not NixOS then source conda env
        # >>> conda initialize >>>
        # !! Contents within this block are managed by 'conda init' !!
        __conda_setup="$($CONDA_ROOT/bin/conda 'shell.zsh' 'hook' 2>/dev/null)"
        if [ $? -eq 0 ]; then
          eval "$__conda_setup"
        else
          if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
            . "$CONDA_ROOT/etc/profile.d/conda.sh"
          else
            export PATH="$CONDA_ROOT/bin:$PATH"
          fi
        fi
        unset __conda_setup
        # <<< conda initialize <<<

        export NVM_DIR="$HOME/.config/nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
      fi

      # Use vim keys in tab complete menu:
      bindkey -M menuselect 'h' vi-backward-char
      bindkey -M menuselect 'k' vi-up-line-or-history
      bindkey -M menuselect 'l' vi-forward-char
      bindkey -M menuselect 'j' vi-down-line-or-history

      # adding important bin to bash
      export PATH=$PATH:$HOME/.local/bin
      export PATH=$PATH:$HOME/.cargo/bin

      eval "$(starship init zsh)"
    '';
  };

  programs.bat = {
    enable = true;
    config = {
      style = "plain";
    };
    extraPackages = [];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      bg = lib.mkForce "";
    };
  };
}
