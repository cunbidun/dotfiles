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
  tailnetDomain = userdata.tailnetDomain or null;
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

    publicBaseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Externally reachable URL used for webhook callbacks and editor links.";
    };

    ssl = {
      enable = mkEnableOption "terminate HTTPS directly in the n8n container";

      domain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description =
          "Domain name encoded into the TLS certificate. Defaults to <hostname>.<tailnetDomain> when available.";
      };

      certDir = mkOption {
        type = types.str;
        default = "/var/lib/tailscale/n8n";
        description = "Directory on the host that stores TLS certificate material.";
      };

      certFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Absolute path to the TLS certificate file. Defaults to <certDir>/cert.pem.";
      };

      keyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Absolute path to the TLS private key file. Defaults to <certDir>/key.pem.";
      };

      manageCert = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically issue/renew the certificate via `tailscale cert` when true.";
      };
    };
  };

  config = mkIf cfg.enable (let
    portStr = toString cfg.port;
    sslEnabled = cfg.ssl.enable;
    sslCertFile =
      if cfg.ssl.certFile != null then cfg.ssl.certFile else "${cfg.ssl.certDir}/cert.pem";
    sslKeyFile =
      if cfg.ssl.keyFile != null then cfg.ssl.keyFile else "${cfg.ssl.certDir}/key.pem";
    defaultTailHost =
      if tailnetDomain == null
      then null
      else "${config.networking.hostName}.${tailnetDomain}";
    sslDomain = if cfg.ssl.domain != null then cfg.ssl.domain else defaultTailHost;
    protocol = if sslEnabled then "https" else "http";
    publicUrl =
      if cfg.publicBaseUrl != null then cfg.publicBaseUrl
      else if sslEnabled && sslDomain != null then "${protocol}://${sslDomain}:${portStr}"
      else "${protocol}://localhost:${portStr}";
    sslMountDirs =
      if sslEnabled
      then
        let
          certDirHost = builtins.dirOf sslCertFile;
          keyDirHost = builtins.dirOf sslKeyFile;
        in
          unique (
            if certDirHost == keyDirHost
            then [certDirHost]
            else [certDirHost keyDirHost]
          )
      else [];
  in {
    assertions = [
      {
        assertion = !(sslEnabled && cfg.ssl.manageCert && sslDomain == null);
        message =
          "services.n8nSimple.ssl.domain (or userdata.tailnetDomain) must be set when enabling managed TLS.";
      }
      {
        assertion = !(sslEnabled && !cfg.ssl.manageCert
          && (cfg.ssl.certFile == null || cfg.ssl.keyFile == null));
        message =
          "Provide services.n8nSimple.ssl.certFile/keyFile when disabling managed TLS certificates.";
      }
    ];

    systemd.tmpfiles.rules =
      [
        "d ${dataDir} 0777 root root -"
      ]
      ++ optional (sslEnabled && cfg.ssl.manageCert)
      "d ${cfg.ssl.certDir} 0750 ${userdata.username} root -";

    systemd.services."tailscale-cert-n8n" = mkIf (sslEnabled && cfg.ssl.manageCert) {
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
          ${sslDomain}

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
          echo "n8n TLS material updated; restart podman-n8n.service to pick up the change." >&2
        fi
      '';
      wantedBy = ["multi-user.target"];
    };

    systemd.timers."tailscale-cert-n8n" = mkIf (sslEnabled && cfg.ssl.manageCert) {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services.podman-n8n = mkIf (sslEnabled && cfg.ssl.manageCert) {
      requires = ["tailscale-cert-n8n.service"];
      after = ["tailscale-cert-n8n.service"];
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      ensureDatabases = ["n8n"];
      ensureUsers = [
        {
          name = "n8n";
          ensureDBOwnership = true;
        }
      ];
      # Limit to local connections and allow passwordless access from the host.
      settings.listen_addresses = lib.mkForce "127.0.0.1";
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
      volumes =
        [
          "${dataDir}:/home/node/.n8n"
        ]
        ++ (map (dir: "${dir}:${dir}:ro") sslMountDirs);
      extraOptions = [
        "--network=host"
      ];
      environment =
        {
          DB_TYPE = "postgresdb";
          DB_POSTGRESDB_HOST = "127.0.0.1";
          DB_POSTGRESDB_PORT = "5432";
          DB_POSTGRESDB_DATABASE = "n8n";
          DB_POSTGRESDB_USER = "n8n";
          N8N_BASIC_AUTH_ACTIVE = "false";
          N8N_PROTOCOL = protocol;
          N8N_HOST = cfg.host;
          N8N_PORT = portStr;
          N8N_EDITOR_BASE_URL = publicUrl;
          WEBHOOK_URL = publicUrl;
          N8N_SECURE_COOKIE = if sslEnabled then "true" else "false";
          N8N_DIAGNOSTICS_ENABLED = "false";
          N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
          N8N_TEMPLATES_ENABLED = "false";
          N8N_DIAGNOSTICS_CONFIG_FRONTEND = "";
          N8N_DIAGNOSTICS_CONFIG_BACKEND = "";
          N8N_RUNNERS_ENABLED = "true";
          N8N_BLOCK_ENV_ACCESS_IN_NODE = "true";
          N8N_GIT_NODE_DISABLE_BARE_REPOS = "true";
          GENERIC_TIMEZONE = timezone;
          TZ = timezone;
        }
        // optionalAttrs sslEnabled {
          N8N_SSL_CERT = sslCertFile;
          N8N_SSL_KEY = sslKeyFile;
        };
    };
  });
}
