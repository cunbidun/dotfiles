{
  pkgs,
  lib,
  config,
  ...
}: let
  tmuxConfigDir = "${config.home.homeDirectory}/.config/tmux";
  tmuxConfigPath = "${tmuxConfigDir}/tmux.conf";
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
        # Single-line status bar. Reset status-format back to the built-in
        # default so re-sourcing into an existing server clears any prior
        # two-row spacer state instead of stacking onto it.
        set -gu status-format
        set -g status on
        setw -g xterm-keys on

        # -- theme --
        # Reference only the terminal's ANSI palette (colour0-15) and its
        # default fg/bg -- never hex. The terminal (kitty) owns these slots, so
        # the bar follows whatever theme kitty is set to (including remote
        # sessions over SSH, since rendering happens locally) and flips
        # light/dark automatically via `default`. No per-theme files, no
        # runtime sourcing. colour2 gives the active window each palette's
        # green accent; colour0 is the dim border / copy-mode surface.
        set -g status-style                "bg=default,fg=default"
        set -g status-left-style           "bg=default,fg=default"
        set -g status-right-style          "bg=default,fg=colour8"
        set -g window-status-style         "bg=default,fg=colour8"
        set -g window-status-current-style "bg=colour2,fg=colour0,bold"
        set -g pane-border-style           "fg=colour0"
        set -g pane-active-border-style    "fg=colour2"
        set -g message-style               "bg=colour2,fg=colour0"
        set -g mode-style                  "bg=colour0,fg=default"

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
