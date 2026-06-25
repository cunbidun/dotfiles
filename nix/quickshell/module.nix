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
      bluezAgentPython = pkgs.python3.withPackages (pythonPkgs: [
        pythonPkgs.dbus-python
        pythonPkgs.pygobject3
      ]);
      backendRuntimeDeps = [
        pkgs.bash
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.systemd
        pkgs.wireplumber
      ];
      backendPath = lib.makeBinPath backendRuntimeDeps;
      backendScript = pkgs.writeShellScriptBin "quickshell-backend" ''
        export PYTHONUNBUFFERED=1
        export PATH='${backendPath}:/run/current-system/sw/bin:$PATH'
        exec ${bluezAgentPython}/bin/python ${repoPath}/backend/bluez_agent.py
      '';
      runtimeDeps = [
        pkgs.bash
        pkgs.coreutils
        pkgs.curl
        pkgs.gawk
        pkgs.procps
        pkgs.quickshell
        pkgs.gnused
        backendScript
        pkgs.brightnessctl
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
          X-SwitchMethod = "keep-old";
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
          X-SwitchMethod = "keep-old";
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
    }
  );
}
