{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cunbidun.quickshell;
  scripts = import ../home-manager/scripts.nix {inherit pkgs;};
in {
  options.cunbidun.quickshell.enable = lib.mkEnableOption "QuickShell desktop shell from nix/quickshell";

  config = lib.mkIf cfg.enable (
    let
      system = pkgs.stdenv.hostPlatform.system;
      repoPath = "${config.home.homeDirectory}/dotfiles/nix/quickshell";
      configPath = "${config.home.homeDirectory}/.config/quickshell/cunbidun";
      stylixStatePath = "${config.home.homeDirectory}/.local/state/stylix";
      bluezAgentPython = pkgs.python3.withPackages (pythonPkgs: [
        pythonPkgs.dbus-python
        pythonPkgs.pygobject3
      ]);
      backendScript = pkgs.writeShellScriptBin "quickshell-backend" ''
        export PYTHONUNBUFFERED=1
        exec ${bluezAgentPython}/bin/python ${repoPath}/backend/bluez_agent.py
      '';
      runtimeDeps = [
        pkgs.bash
        pkgs.coreutils
        pkgs.curl
        pkgs.gawk
        pkgs.inotify-tools
        pkgs.procps
        pkgs.quickshell
        pkgs.gnused
        backendScript
        pkgs.brightnessctl
        pkgs.darkman
        pkgs.hyprpicker
        pkgs.jq
        pkgs.libnotify
        pkgs.pamixer
        pkgs.pulseaudio
        pkgs.slurp
        pkgs.systemd
        pkgs.theme-manager
        pkgs.wf-recorder
        pkgs.wireplumber
        scripts.wsctl
        inputs.hyprland.packages.${system}.hyprland
      ];
      binPath = lib.makeBinPath runtimeDeps;

      quickshellRunScript = pkgs.writeShellScriptBin "quickshell-run" ''
        set -eo pipefail

        export PATH='${binPath}:/run/current-system/sw/bin:$PATH'
        exec ${pkgs.quickshell}/bin/qs --config cunbidun --no-duplicate
      '';

      quickshellWatchScript = pkgs.writeShellScript "quickshell-watch" ''
        set -euo pipefail

        watch_dir='${configPath}'
        stylix_state_dir='${stylixStatePath}'
        last_restart=0
        debounce_ms=800

        watch_targets=("$watch_dir")
        if [ -L "$watch_dir" ]; then
          watch_dir="$(${pkgs.coreutils}/bin/readlink -f "$watch_dir")"
          watch_targets=("$watch_dir")
        fi
        if [ -d "$stylix_state_dir" ]; then
          watch_targets+=("$stylix_state_dir")
        fi

        while ${pkgs.inotify-tools}/bin/inotifywait \
          --quiet \
          --recursive \
          --event close_write,delete,move \
          --exclude '(^|/)(\.git|node_modules|result)(/|$)|(^|/)\.goutputstream-.*|(~$|\.sw.$)' \
          "''${watch_targets[@]}"; do
          now_ms="$(${pkgs.coreutils}/bin/date +%s%3N)"
          if [ "$last_restart" -ne 0 ] && [ "$((now_ms - last_restart))" -lt "$debounce_ms" ]; then
            continue
          fi
          last_restart="$now_ms"
          ${pkgs.systemd}/bin/systemctl --user restart quickshell-backend.service quickshell.service || true
        done
      '';

      quickshellReloadScript = pkgs.writeShellScriptBin "quickshell-reload" ''
        exec ${pkgs.systemd}/bin/systemctl --user restart quickshell-backend.service quickshell.service
      '';
    in {
      xdg.configFile."quickshell/cunbidun" = {
        force = true;
        source = config.lib.file.mkOutOfStoreSymlink repoPath;
      };

      home.packages = [
        pkgs.quickshell
        backendScript
        quickshellReloadScript
      ];

      systemd.user.services.quickshell-backend = {
        Unit = {
          Description = "QuickShell DBus backend";
          After = ["graphical-session.target" "bluetooth.target"];
          Wants = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = lib.getExe backendScript;
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      systemd.user.services.quickshell = {
        Unit = {
          Description = "QuickShell";
          After = ["graphical-session.target" "quickshell-backend.service"];
          Wants = ["graphical-session.target" "quickshell-backend.service"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = lib.getExe quickshellRunScript;
          Environment = [
            "QS_CONFIG_NAME=cunbidun"
          ];
          KillMode = "mixed";
          TimeoutStopSec = 2;
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      systemd.user.services.quickshell-watch = {
        Unit = {
          Description = "Watch QuickShell source and restart on change";
          After = ["graphical-session.target"];
          Wants = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash ${quickshellWatchScript}";
          Restart = "always";
          RestartSec = 1;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    }
  );
}
