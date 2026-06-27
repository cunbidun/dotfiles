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

      autoload -Uz add-zsh-hook

      refresh_cli_theme() {
        local theme_name
        theme_name="$(command cat "$HOME/.local/state/theme-manager/current-theme-name.txt" 2>/dev/null)"
        [[ "$theme_name" == "$CURRENT_THEME_NAME" ]] && return
        export CURRENT_THEME_NAME="$theme_name"

        case "$theme_name" in
          catppuccin-light)
            export BAT_THEME="Catppuccin Latte"
            export FZF_DEFAULT_OPTS="--color=bg+:#CCD0DA,bg:#EFF1F5,spinner:#DC8A78,hl:#D20F39 --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 --color=selected-bg:#BCC0CC --color=border:#9CA0B0,label:#4C4F69"
            ;;
          catppuccin-dark)
            export BAT_THEME="Catppuccin Mocha"
            export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4"
            ;;
          everforest-light)
            export BAT_THEME="base16"
            export FZF_DEFAULT_OPTS="--color=bg+:#EDEADA,bg:#FFFBEE,spinner:#8DA101,hl:#F85552 --color=fg:#5C6A72,header:#F85552,info:#3A94C5,pointer:#8DA101 --color=marker:#35A77C,fg+:#5C6A72,prompt:#8DA101,hl+:#F85552 --color=selected-bg:#F0F2D4 --color=border:#BEC5B2,label:#5C6A72"
            ;;
          everforest-dark)
            export BAT_THEME="base16"
            export FZF_DEFAULT_OPTS="--color=bg+:#414B50,bg:#272E33,spinner:#A7C080,hl:#E67E80 --color=fg:#D3C6AA,header:#E67E80,info:#7FBBB3,pointer:#A7C080 --color=marker:#83C092,fg+:#D3C6AA,prompt:#A7C080,hl+:#E67E80 --color=selected-bg:#464E53 --color=border:#4F5B58,label:#D3C6AA"
            ;;
          rose-pine-light)
            export BAT_THEME="base16"
            export FZF_DEFAULT_OPTS="--color=bg+:#F2E9E1,bg:#FAF4ED,spinner:#D7827E,hl:#B4637A --color=fg:#575279,header:#B4637A,info:#907AA9,pointer:#D7827E --color=marker:#286983,fg+:#575279,prompt:#907AA9,hl+:#B4637A --color=selected-bg:#DFDAD9 --color=border:#CECACD,label:#575279"
            ;;
          rose-pine-dark)
            export BAT_THEME="base16"
            export FZF_DEFAULT_OPTS="--color=bg+:#26233A,bg:#191724,spinner:#EBBCBA,hl:#EB6F92 --color=fg:#E0DEF4,header:#EB6F92,info:#C4A7E7,pointer:#EBBCBA --color=marker:#31748F,fg+:#E0DEF4,prompt:#C4A7E7,hl+:#EB6F92 --color=selected-bg:#403D52 --color=border:#524F67,label:#E0DEF4"
            ;;
          default-light)
            export BAT_THEME="GitHub"
            export FZF_DEFAULT_OPTS="--color=bg+:#F2F2F7,bg:#FFFFFF,spinner:#007AFF,hl:#FF3B30 --color=fg:#1D1D1F,header:#FF3B30,info:#5856D6,pointer:#007AFF --color=marker:#34C759,fg+:#000000,prompt:#007AFF,hl+:#FF3B30 --color=selected-bg:#E5E5EA --color=border:#C7C7CC,label:#1D1D1F"
            ;;
          *)
            export BAT_THEME="Visual Studio Dark+"
            export FZF_DEFAULT_OPTS="--color=bg+:#2C2C2E,bg:#1C1C1E,spinner:#0A84FF,hl:#FF453A --color=fg:#F2F2F7,header:#FF453A,info:#BF5AF2,pointer:#0A84FF --color=marker:#30D158,fg+:#FFFFFF,prompt:#0A84FF,hl+:#FF453A --color=selected-bg:#3A3A3C --color=border:#545458,label:#F2F2F7"
            ;;
        esac
      }

      add-zsh-hook precmd refresh_cli_theme
      add-zsh-hook preexec refresh_cli_theme
      refresh_cli_theme

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
