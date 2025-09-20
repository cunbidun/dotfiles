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

    enableTray = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the system tray icon for theme-manager.";
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
    # Single package now always contains tray dependencies; enableTray just toggles runtime usage
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
        description = "Theme Manager daemon" + lib.optionalString cfg.enableTray " with tray icon";
        After = [config.wayland.systemd.target];
        PartOf = [config.wayland.systemd.target];
        X-Restart-Triggers = [
          "${config.xdg.configFile."theme-manager/config.yaml".source}"
        ];
      };

      Service = {
        ExecStart = "${pkgs.theme-manager}/bin/theme-manager" + lib.optionalString cfg.enableTray " --tray";
        Restart = "always";
        RestartSec = "10";
        Environment = lib.optionals cfg.enableTray [
          "DISPLAY=:0"
          "THEME_MANAGER_TRAY=1"
        ];
      };
    };
  };
}
