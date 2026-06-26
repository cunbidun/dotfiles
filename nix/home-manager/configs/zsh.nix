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

      # Prefer 1Password SSH agent when available.
      if [ -S "$HOME/.1password/agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
      fi

      bat() {
        for arg in "$@"; do
          case "$arg" in
            --theme|--theme=*) command bat "$@"; return ;;
          esac
        done

        case "$(cat "$HOME/.local/state/theme-manager/current-theme-name.txt" 2>/dev/null)" in
          catppuccin-light) command bat --theme="Catppuccin Latte" "$@" ;;
          catppuccin-dark) command bat --theme="Catppuccin Mocha" "$@" ;;
          default-light) command bat --theme="GitHub" "$@" ;;
          *) command bat --theme="Visual Studio Dark+" "$@" ;;
        esac
      }

      eval "$(starship init zsh)"
      eval "$(atuin init zsh --disable-up-arrow)"

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
