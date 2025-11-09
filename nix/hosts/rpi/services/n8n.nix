{
  config,
  lib,
  pkgs,
  userdata,
  ...
}:
with lib; let
  cfg = config.services.n8nSimple;
  dataDir = cfg.dataDir;
  timezone = userdata.timeZone or "UTC";
  tailnetDomain =
    userdata.tailnetDomain
    or (throw "userdata.tailnetDomain must be set for services.n8nSimple");
  portStr = toString cfg.port;
  sslCertDir = "/var/lib/tailscale/n8n";
  sslCertFile = "${sslCertDir}/cert.pem";
  sslKeyFile = "${sslCertDir}/key.pem";
  tailHost = "${config.networking.hostName}.${tailnetDomain}";
  publicUrl = "https://${tailHost}:${portStr}";
  sslMountDirs = [sslCertDir];

  n8nDataDir = "${dataDir}/n8n";
  postgresDataDir = "${dataDir}/postgres";
  redisDataDir = "${dataDir}/redis";
  signalDataDir = "/var/lib/signal-cli-rest";
  composeProjectName = "n8n";
  databaseUser = "n8n";
  databaseName = "n8n";
  databasePassword = "n8n-secret";

  composeFormat = pkgs.formats.yaml {};
  commonEnv = {
    DB_TYPE = "postgresdb";
    DB_POSTGRESDB_HOST = "127.0.0.1";
    DB_POSTGRESDB_PORT = "5432";
    DB_POSTGRESDB_DATABASE = databaseName;
    DB_POSTGRESDB_USER = databaseUser;
    DB_POSTGRESDB_PASSWORD = databasePassword;
    EXECUTIONS_MODE = "queue";
    QUEUE_BULL_REDIS_HOST = "127.0.0.1";
    QUEUE_BULL_REDIS_PORT = "6379";
    N8N_BASIC_AUTH_ACTIVE = "false";
    N8N_EDITOR_BASE_URL = publicUrl;
    WEBHOOK_URL = publicUrl;
    N8N_SECURE_COOKIE = "true";
    N8N_DIAGNOSTICS_ENABLED = "false";
    N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
    N8N_TEMPLATES_ENABLED = "false";
    N8N_DIAGNOSTICS_CONFIG_FRONTEND = "";
    N8N_DIAGNOSTICS_CONFIG_BACKEND = "";
    N8N_BLOCK_ENV_ACCESS_IN_NODE = "true";
    N8N_GIT_NODE_DISABLE_BARE_REPOS = "true";
    N8N_HOST = cfg.host;
    N8N_PORT = portStr;
    GENERIC_TIMEZONE = timezone;
    TZ = timezone;
  };

  composeConfig = {
    services = {
      postgres = {
        image = "docker.io/library/postgres:16-alpine";
        restart = "unless-stopped";
        network_mode = "host";
        environment = {
          POSTGRES_DB = databaseName;
          POSTGRES_USER = databaseUser;
          POSTGRES_PASSWORD = databasePassword;
        };
        command = [
          "postgres"
          "-c"
          "listen_addresses=127.0.0.1"
        ];
        volumes = [
          "${postgresDataDir}:/var/lib/postgresql/data"
        ];
      };

      redis = {
        image = "docker.io/library/redis:7-alpine";
        restart = "unless-stopped";
        network_mode = "host";
        command = [
          "redis-server"
          "--appendonly"
          "yes"
          "--bind"
          "127.0.0.1"
          "--protected-mode"
          "yes"
        ];
        volumes = [
          "${redisDataDir}:/data"
        ];
      };

      signal = {
        image = "docker.io/bbernhard/signal-cli-rest-api:latest";
        restart = "unless-stopped";
        network_mode = "host";
        volumes = [
          "${signalDataDir}:/home/.local/share/signal-cli"
        ];
        environment = {MODE = "json-rpc";};
      };

      n8n = let
        commonEnv = {
          DB_TYPE = "postgresdb";
          DB_POSTGRESDB_HOST = "127.0.0.1";
          DB_POSTGRESDB_PORT = "5432";
          DB_POSTGRESDB_DATABASE = databaseName;
          DB_POSTGRESDB_USER = databaseUser;
          DB_POSTGRESDB_PASSWORD = databasePassword;
          EXECUTIONS_MODE = "queue";
          QUEUE_BULL_REDIS_HOST = "127.0.0.1";
          QUEUE_BULL_REDIS_PORT = "6379";
          N8N_BASIC_AUTH_ACTIVE = "false";
          N8N_HOST = cfg.host;
          N8N_PORT = portStr;
          N8N_EDITOR_BASE_URL = publicUrl;
          WEBHOOK_URL = publicUrl;
          N8N_SECURE_COOKIE = "true";
          N8N_DIAGNOSTICS_ENABLED = "false";
          N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
          N8N_TEMPLATES_ENABLED = "false";
          N8N_DIAGNOSTICS_CONFIG_FRONTEND = "";
          N8N_DIAGNOSTICS_CONFIG_BACKEND = "";
          N8N_BLOCK_ENV_ACCESS_IN_NODE = "true";
          N8N_GIT_NODE_DISABLE_BARE_REPOS = "true";
          GENERIC_TIMEZONE = timezone;
          TZ = timezone;
        };
      in {
        image = cfg.image;
        restart = "unless-stopped";
        depends_on = ["postgres" "redis" "signal"];
        network_mode = "host";
        environment =
          commonEnv
          // {
            N8N_PROTOCOL = "https";
            N8N_RUNNERS_ENABLED = "true";
            N8N_SSL_CERT = sslCertFile;
            N8N_SSL_KEY = sslKeyFile;
          };
        volumes =
          [
            "${n8nDataDir}:/home/node/.n8n"
          ]
          ++ (map (dir: "${dir}:${dir}:ro") sslMountDirs);
      };

      worker = {
        image = cfg.image;
        restart = "unless-stopped";
        depends_on = ["postgres" "redis"];
        network_mode = "host";
        command = ["worker"];
        environment =
          commonEnv
          // {
            N8N_RUNNERS_ENABLED = "false";
            N8N_PROTOCOL = "http";
          };
        volumes = [
          "${n8nDataDir}:/home/node/.n8n"
        ];
      };
    };
  };
  composeFile = composeFormat.generate "n8n-compose.yaml" composeConfig;
in {
  options.services.n8nSimple = {
    enable = mkEnableOption "simple n8n workflow automation server (container-backed)";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/n8n";
      description = "Directory on the host that stores the n8n application data.";
    };

    image = mkOption {
      type = types.str;
      default = "docker.n8n.io/n8nio/n8n:1.118.2";
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
  };

  config = mkIf cfg.enable (let
    directories = [
      dataDir
      n8nDataDir
      postgresDataDir
      redisDataDir
      signalDataDir
    ];
  in {
    systemd.tmpfiles.rules =
      (map (dir: "d ${dir} 0777 root root -") directories)
      ++ ["d ${sslCertDir} 0750 ${userdata.username} root -"];

    systemd.services."tailscale-cert-n8n" = {
      description = "Fetch/refresh Tailscale TLS cert for n8n";
      after = ["network-online.target" "tailscale.service"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        set -euo pipefail
        tmpdir="$(${pkgs.coreutils}/bin/mktemp -d)"
        trap 'rm -rf "$tmpdir"' EXIT

        ${pkgs.tailscale}/bin/tailscale cert \
          --cert-file "$tmpdir/cert.pem" \
          --key-file  "$tmpdir/key.pem" \
          ${tailHost}

        changed=0
        if [ ! -f ${sslCertFile} ] || ! ${pkgs.diffutils}/bin/cmp -s "$tmpdir/cert.pem" ${sslCertFile}; then
          changed=1
        fi
        if [ ! -f ${sslKeyFile} ] || ! ${pkgs.diffutils}/bin/cmp -s "$tmpdir/key.pem" ${sslKeyFile}; then
          changed=1
        fi

        ${pkgs.coreutils}/bin/install -Dm640 -o ${userdata.username} -g root "$tmpdir/cert.pem" ${sslCertFile}
        ${pkgs.coreutils}/bin/install -Dm640 -o ${userdata.username} -g root "$tmpdir/key.pem" ${sslKeyFile}

        if [ "$changed" -eq 1 ]; then
          echo "n8n TLS material updated; restarting n8n-compose.service to pick up the change." >&2
          ${pkgs.systemd}/bin/systemctl try-restart n8n-compose.service
        fi
      '';
      wantedBy = ["multi-user.target"];
    };

    systemd.timers."tailscale-cert-n8n" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services.n8n-compose = {
      description = "n8n automation stack (Podman Compose)";
      requires = ["tailscale-cert-n8n.service"];
      after = ["tailscale-cert-n8n.service" "network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      path = [
        pkgs.podman
        pkgs.podman-compose
        pkgs.coreutils
        pkgs.bash
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} -p ${composeProjectName} up -d --remove-orphans";
        ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f ${composeFile} -p ${composeProjectName} down";
        TimeoutStartSec = 600;
        TimeoutStopSec = 120;
      };
      environment = {
        PODMAN_SYSTEMD_UNIT = "%n";
      };
    };

    virtualisation.podman.enable = mkDefault true;
  });
}
