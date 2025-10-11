{
  pkgs,
  lib,
  config,
  ...
}: let
  tmux-plugin-list = with pkgs.tmuxPlugins; [
    extrakto
  ];

  local-plugin-dir = pkgs.runCommand "tmux-plugins" {} ''
    mkdir -p $out

    # Regular plugins
    ${lib.concatMapStrings (plugin: ''
        ln -s "${plugin}" "$out/${plugin.pname}"
      '')
      tmux-plugin-list}

  '';

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
  home.file.".local/share/tmux-plugins".source = local-plugin-dir;

  programs.tmux = {
    enable = true;
    mouse = true;
    historyLimit = 10000;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    terminal = "xterm-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      set -g @plugin_path "~/.local/share/tmux-plugins"
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -g renumber-windows on
      set -sg repeat-time 600
      setw -g xterm-keys on

      # -- key-bind --
      # clear both screen and history
      bind -n C-l send-keys C-l \; run 'sleep 0.2' \; clear-history
      # edit configuration
      bind e new-window -n "tmux.conf" "sh -c '$EDITOR ${tmuxConfigPath}'"
      # reload configuration
      bind r run-shell "${tmuxReloadScript}"
      # kill-session
      bind -n C-q confirm-before -p "kill-session? (y/n)" kill-session

      # pane navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      # pane resizing
      bind -r H resize-pane -L 2
      bind -r J resize-pane -D 2
      bind -r K resize-pane -U 2
      bind -r L resize-pane -R 2

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

      # -- plugin --
      run-shell "#{@plugin_path}/tmuxplugin-extrakto/share/tmux-plugins/extrakto/extrakto.tmux"
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
