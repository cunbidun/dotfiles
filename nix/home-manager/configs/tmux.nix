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

    if ! ${pkgs.tmux}/bin/tmux has-session 2>/dev/null; then
      exit 0
    fi

    ${pkgs.tmux}/bin/tmux source-file ${tmuxConfigPath}
    ${pkgs.tmux}/bin/tmux display-message "tmux config reloaded"
  '';
in {
  programs.tmux = {
    enable = true;
    mouse = true;
    historyLimit = 10000;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    terminal = "xterm-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    # Native options for pane navigation/resizing (replaces h/j/k/l and H/J/K/L bindings)
    customPaneNavigationAndResize = true;
    resizeAmount = 2;

    # Native plugin management
    plugins = [pkgs.tmuxPlugins.extrakto];

    extraConfig = ''
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g renumber-windows on
      set -sg repeat-time 600
      setw -g xterm-keys on

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
    Unit = {
      Description = "Reload tmux after config updates";
    };
    Service = {
      Type = "oneshot";
      ExecStart = tmuxReloadScript;
    };
  };

  systemd.user.paths.tmux-reload = {
    Unit = {
      Description = "Watch tmux config for changes";
    };
    Path = {
      PathModified = tmuxConfigPath;
      PathChanged = tmuxConfigDir;
      Unit = "tmux-reload.service";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
