{
  pkgs,
  lib,
  config,
  ...
}: let
  tmuxConfigDir = "${config.home.homeDirectory}/.config/tmux";
  tmuxConfigPath = "${tmuxConfigDir}/tmux.conf";
  themeDir = "${config.home.homeDirectory}/.local/share/theme-manager/tmux";
  themeStatePath = "${config.home.homeDirectory}/.local/state/theme-manager/tmux-theme.conf";
  tmuxThemePath = theme: polarity: "${themeDir}/theme-manager-${theme}-${polarity}.conf";
  tmuxReloadScript = pkgs.writeShellScript "tmux-reload" ''
    set -euo pipefail
    socket="$XDG_RUNTIME_DIR/tmux-$(id -u)/default"
    tmux=(${pkgs.tmux}/bin/tmux)
    if [ -S "$socket" ]; then
      tmux+=(-S "$socket")
    fi

    if ! "''${tmux[@]}" has-session 2>/dev/null; then
      exit 0
    fi

    "''${tmux[@]}" source-file ${tmuxConfigPath}
    "''${tmux[@]}" display-message "tmux config reloaded"
  '';
in {
  options.themeManager.tmux.themePath = lib.mkOption {
    type = lib.types.functionTo (lib.types.functionTo lib.types.str);
    default = tmuxThemePath;
    readOnly = true;
    description = "Return theme-manager's tmux theme path for a theme and polarity.";
  };

  config = {
    programs.tmux = {
      enable = true;
      mouse = true;
      historyLimit = 10000;
      baseIndex = 1;
      escapeTime = 10;
      keyMode = "vi";
      terminal = "tmux-256color";
      shell = "${pkgs.zsh}/bin/zsh";

      customPaneNavigationAndResize = true;
      resizeAmount = 2;

      plugins = [pkgs.tmuxPlugins.extrakto];

      extraConfig = ''
        set -g default-terminal "tmux-256color"
        set -g focus-events on
        set -ga terminal-overrides ",tmux-256color:RGB"
        set -g renumber-windows on
        set -sg repeat-time 600
        set -g status 2
        set -g status-format[0] "#[bg=default,fg=default]"
        setw -g xterm-keys on
        source-file -q ${themeStatePath}

        # -- key-bind --
        bind -n C-l send-keys C-l \; run 'sleep 0.2' \; clear-history
        bind e new-window -n "tmux.conf" "sh -c '$EDITOR ${tmuxConfigPath}'"
        bind r run-shell "${tmuxReloadScript}"
        bind -n C-q confirm-before -p "kill-session? (y/n)" kill-session

        # window navigation
        unbind n
        unbind p
        bind -r C-h previous-window
        bind -r C-l next-window

        # -- copy mode --
        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi C-v send -X rectangle-toggle
        bind -T copy-mode-vi y send -X copy-selection-and-cancel
        bind -T copy-mode-vi Escape send -X cancel

        bind b copy-mode\;\
          send-keys -X start-of-line\;\
          send-keys -X search-forward "$USER@"
      '';
    };

    home.file = {
      ".local/share/theme-manager/tmux/theme-manager-default-light.conf".source = ./default-light.conf;
      ".local/share/theme-manager/tmux/theme-manager-default-dark.conf".source = ./default-dark.conf;
      ".local/share/theme-manager/tmux/theme-manager-everforest-light.conf".source = ./everforest-light.conf;
      ".local/share/theme-manager/tmux/theme-manager-everforest-dark.conf".source = ./everforest-dark.conf;
      ".local/share/theme-manager/tmux/theme-manager-catppuccin-light.conf".source = ./catppuccin-light.conf;
      ".local/share/theme-manager/tmux/theme-manager-catppuccin-dark.conf".source = ./catppuccin-dark.conf;
    };

    systemd.user.services.tmux-reload = {
      Unit.Description = "Reload tmux after config updates";
      Service = {
        Type = "oneshot";
        ExecStart = tmuxReloadScript;
      };
    };

    systemd.user.paths.tmux-reload = {
      Unit.Description = "Watch tmux config for changes";
      Path = {
        PathModified = tmuxConfigPath;
        PathChanged = tmuxConfigDir;
        Unit = "tmux-reload.service";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
