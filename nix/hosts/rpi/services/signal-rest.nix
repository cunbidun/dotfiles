{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.signalRest;
in {
  options.services.signalRest = {
    enable = mkEnableOption "signal-cli REST API bridge";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/signal-cli-rest";
      description = "Directory to persist signal-cli state (stores keys and device links).";
    };

    mode = mkOption {
      type = types.enum ["normal" "native" "json-rpc"];
      default = "json-rpc";
      description = "Execution mode for signal-cli-rest-api (see upstream docs).";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Host port exposed for the REST API.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 root root -"
    ];

    virtualisation.oci-containers.containers.signal-cli-rest = {
      autoStart = true;
      image = "docker.io/bbernhard/signal-cli-rest-api:latest";
      ports = [
        "127.0.0.1:${toString cfg.port}:8080"
      ];
      volumes = [
        "${cfg.dataDir}:/home/.local/share/signal-cli"
      ];
      environment = {
        MODE = cfg.mode;
      };
    };
  };
}
