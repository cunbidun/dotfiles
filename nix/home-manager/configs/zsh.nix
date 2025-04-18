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

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -d "/snap/bin" ] && export PATH=$PATH:/snap/bin

      if [ ! -d "/etc/nixos" ]; then
        export CONDA_CHANGEPS1=false
        export PATH=/etc/profiles/per-user/$USER/bin:$PATH

        # set conda root correctly depending on the system.
        # if it's linux then /home/$USER/miniconda3
        # if it's mac then /Users/$USER/miniconda3

        if [ "$(uname)" = "Darwin" ]; then
          export CONDA_ROOT="/Users/$USER/miniconda3"
        else
          export CONDA_ROOT="/home/$USER/miniconda3"
        fi

        # if archlinux then source conda env
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

      # vi mode taken from https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
      bindkey -v
      export KEYTIMEOUT=1

      # Change cursor shape for different vi modes.
      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] ||
          [[ $1 = 'block' ]]; then
          echo -ne '\e[1 q'
        elif [[ ''${KEYMAP} == main ]] ||
          [[ ''${KEYMAP} == viins ]] ||
          [[ ''${KEYMAP} = "" ]] ||
          [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'
        fi
      }
      zle -N zle-keymap-select
      zle-line-init() {
        zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
        echo -ne "\e[5 q"
      }
      zle -N zle-line-init
      echo -ne '\e[5 q'                # Use beam shape cursor on startup.
      preexec() { echo -ne '\e[5 q'; } # Use beam shape cursor for each new prompt.
      #
      # Use vim keys in tab complete menu:
      bindkey -M menuselect 'h' vi-backward-char
      bindkey -M menuselect 'k' vi-up-line-or-history
      bindkey -M menuselect 'l' vi-forward-char
      bindkey -M menuselect 'j' vi-down-line-or-history

      # adding important bin to bash
      export PATH=$PATH:$HOME/.local/bin
      export PATH=$PATH:$HOME/.cargo/bin

      export BAT_STYLE="plain"

      eval "$(starship init zsh)"
    '';
  };
}
