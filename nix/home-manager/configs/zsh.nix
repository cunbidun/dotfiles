{
  pkgs,
  lib,
  config,
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
  programs.eza.enable = true;

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
