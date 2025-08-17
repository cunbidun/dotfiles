{
  config,
  nixosConfig,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.vicinae;
in {
  options.services.vicinae = {
    enable = mkEnableOption "vicinae launcher daemon" // {default = true;};

    package = mkOption {
      type = types.package;
      default = pkgs.vicinae;
      defaultText = literalExpression "pkgs.vicinae";
      description = "The vicinae package to use.";
    };

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to start the vicinae daemon automatically on login.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    # https://docs.vicinae.com/theming#creating-a-custom-theme
    home.file.".config/vicinae/themes/custom.json" = {
      text = builtins.toJSON {
        version = "1.0.0";
        appearance = "${config.lib.stylix.colors.variant}";
        icon = "";
        name = "Custom Theme";
        description = "Theme generated from NixOS defaults colorScheme";
        palette = {
          background = "#${config.lib.stylix.colors.base01}";
          foreground = "#${config.lib.stylix.colors.base06}";
          blue = "#${config.lib.stylix.colors.base0D}";
          green = "#${config.lib.stylix.colors.base0B}";
          magenta = "#${config.lib.stylix.colors.base0E}";
          orange = "#${config.lib.stylix.colors.base09}";
          purple = "#${config.lib.stylix.colors.base0F}";
          red = "#${config.lib.stylix.colors.base08}";
          yellow = "#${config.lib.stylix.colors.base0A}";
          cyan = "#${config.lib.stylix.colors.base0C}";
        };
      };
    };

    systemd.user.services.vicinae = {
      Unit = {
        Description = "Vicinae launcher daemon";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/vicinae server";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = mkIf cfg.autoStart {
        WantedBy = ["graphical-session.target"];
      };
    };

    # One-shot service to restart vicinae
    systemd.user.services.vicinae-restart = {
      Unit = {
        Description = "Restart vicinae service";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --user restart vicinae.service";
      };
    };

    # Path watcher to restart vicinae when config changes
    systemd.user.paths.vicinae-config-watcher = {
      Unit = {
        Description = "Watch vicinae config file for changes";
      };
      Path = {
        # Watch both the file and the directory to catch file recreations
        PathModified = "%h/.config/vicinae/themes/custom.json";
        PathChanged = "%h/.config/vicinae/themes";
        Unit = "vicinae-restart.service";
      };
      Install = mkIf cfg.autoStart {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
