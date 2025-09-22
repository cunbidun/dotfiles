{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.theme-manager;
  hook = pkgs.writeScriptBin "theme-change-hook" cfg.hookScriptContent;
in {
  options.services.theme-manager = {
    enable = lib.mkEnableOption "theme-manager";

    # Tray is now always enabled; option retained only for backward compatibility (no-op)
    enableTray = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "(Deprecated) Previously toggled tray; tray is now always enabled.";
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of themes to cycle through.";
    };

    nvimThemeMap = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Mapping from theme names to Neovim colorscheme names.";
      example = {
        nord = "nord";
        catppuccin = "catppuccin";
        default = "vscode";
      };
    };

    hookScriptContent = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Full Bash script contents to run when theme changes.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Single package always contains tray dependencies; tray always active
    home.packages = [pkgs.theme-manager];

    xdg.configFile."theme-manager/config.yaml".text = ''
      themes:
      ${lib.concatStringsSep "\n" (map (t: "  - " + t) cfg.themes)}

      nvimThemeMap:
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (theme: nvimTheme: "  ${theme}: ${nvimTheme}") cfg.nvimThemeMap)}

      script: "${lib.getExe hook}"
    '';

    systemd.user.services."theme-manager" = {
      Install = {
        WantedBy = [config.wayland.systemd.target];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        After = [config.wayland.systemd.target];
        PartOf = [config.wayland.systemd.target];
        X-Restart-Triggers = [
          "${config.xdg.configFile."theme-manager/config.yaml".source}"
        ];
      };

      Service = {
        ExecStart = "${pkgs.theme-manager}/bin/theme-manager";
        Restart = "always";
        RestartSec = "1";
        Environment = [
          "DISPLAY=:0"
        ];
      };
    };
  };
}
