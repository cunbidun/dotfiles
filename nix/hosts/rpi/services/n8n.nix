{
  config,
  lib,
  pkgs,
  userdata,
  ...
}:
with lib; let
  cfg = config.services.n8n;
  dataDir = cfg.dataDir;
  timezone = userdata.timeZone or "UTC";
  portStr = toString cfg.port;
  publicUrl =
    if cfg.publicBaseUrl == null then "http://localhost:${portStr}" else cfg.publicBaseUrl;
in {
  options.services.n8n = {
    enable = mkEnableOption "n8n workflow automation server";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/n8n";
      description = "Directory on the host that stores the n8n application data.";
    };

    image = mkOption {
      type = types.str;
      default = "docker.n8n.io/n8nio/n8n:1.64.0";
      description = "Container image tag to deploy for n8n.";
    };

    port = mkOption {
      type = types.port;
      default = 5678;
      description = "Port the n8n editor/webhook server listens on.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Host/interface n8n binds to inside the container.";
    };

    publicBaseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Externally reachable URL used for webhook callbacks and editor links.";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0777 root root -"
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      ensureDatabases = ["n8n"];
      ensureUsers = [
        {
          name = "n8n";
          ensurePermissions = {
            "DATABASE n8n" = "ALL PRIVILEGES";
          };
        }
      ];
      # Limit to local connections and allow passwordless access from the host.
      settings.listen_addresses = "127.0.0.1";
      authentication = ''
        local   n8n     n8n                     trust
        host    n8n     n8n     127.0.0.1/32    trust
      '';
    };

    virtualisation.podman.enable = mkDefault true;
    virtualisation.oci-containers.backend = mkDefault "podman";
    virtualisation.oci-containers.containers.n8n = {
      autoStart = true;
      image = cfg.image;
      volumes = [
        "${dataDir}:/home/node/.n8n"
      ];
      ports = [
        "${portStr}:${portStr}"
      ];
      environment = {
        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_HOST = "127.0.0.1";
        DB_POSTGRESDB_PORT = "5432";
        DB_POSTGRESDB_DATABASE = "n8n";
        DB_POSTGRESDB_USER = "n8n";
        N8N_BASIC_AUTH_ACTIVE = "false";
        N8N_PROTOCOL = "http";
        N8N_HOST = cfg.host;
        N8N_PORT = portStr;
        N8N_EDITOR_BASE_URL = publicUrl;
        WEBHOOK_URL = publicUrl;
        GENERIC_TIMEZONE = timezone;
        TZ = timezone;
      };
    };
  };
}
