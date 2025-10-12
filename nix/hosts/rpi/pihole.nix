{
  lib,
  pkgs,
  config,
  userdata,
  ...
}:
with lib; let
  cfg = config.services.pihole;
  tailHost = "${config.networking.hostName}.tail9b4f4d.ts.net";
  certDir = "/var/lib/tailscale/certs";
  certFile = "${certDir}/cert.pem";
  keyFile = "${certDir}/key.pem";
in {
  options.services.pihole = {
    enable = mkEnableOption "pihole service";
    persistanceRoot = mkOption {
      type = types.str;
      default = "/opt/pihole/etc";
    };
  };

  config = mkIf cfg.enable {
    #############
    # Tailscale TLS
    #############
    systemd.tmpfiles.rules = [
      "d ${cfg.persistanceRoot} 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc/pihole 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc/dnsmasq.d 0755 pihole pihole -"
      "d /var/lib/tailscale 0750 root nginx -"
      "d ${certDir} 0750 root nginx -"
    ];
    systemd.services."tailscale-cert" = {
      description = "Fetch/refresh Tailscale TLS cert for ${tailHost}";
      after = ["network-online.target" "tailscale.service"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        set -eu
        mkdir -p ${certDir}
        ${pkgs.tailscale}/bin/tailscale cert \
          --cert-file ${certFile} \
          --key-file  ${keyFile} \
          ${tailHost}

        chown root:nginx ${certFile} ${keyFile}
        chmod 0640 ${certFile} ${keyFile}

        # Reload nginx if running (no-op if not)
        systemctl reload nginx.service || true
      '';
      wantedBy = ["multi-user.target"];
    };
    systemd.timers."tailscale-cert" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily"; # renew check daily
        Persistent = true;
      };
    };

    ########
    # Nginx reverse proxy to Pi-hole web interface
    ########
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."rpi5.tail9b4f4d.ts.net" = {
        onlySSL = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 443;
            ssl = true;
          }
        ];
        sslCertificate = "/var/lib/tailscale/certs/cert.pem";
        sslCertificateKey = "/var/lib/tailscale/certs/key.pem";
        extraConfig = ''
          ssl_stapling off;
          ssl_stapling_verify off;
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
            proxy_read_timeout 300s;
          '';
        };
      };

      virtualHosts."http-redirects" = {
        serverName = "rpi5";
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
          {
            addr = "[::]";
            port = 80;
          }
        ];
        locations."/" = {
          return = "301 https://rpi5.tail9b4f4d.ts.net$request_uri";
        };
      };
    };

    #############
    # Unbound DNS resolver for Pi-hole
    #############
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = ["127.0.0.1" "::1"];
          port = 5335;
          prefetch = true;
          access-control = [
            "127.0.0.0/8 allow"
          ];
        };
      };
    };

    #########
    # Pi-hole in a container
    #########
    services.resolved = {
      enable = false;
    };

    users.users = {
      pihole = {
        uid = 3004;
        group = "pihole";
        isSystemUser = true;
      };
    };

    users.groups = {
      pihole = {
        gid = 3004;
      };
    };

    networking.nameservers = ["1.1.1.1" "1.0.0.1" "9.9.9.9"];

    virtualisation.oci-containers.containers = {
      pihole = {
        autoStart = true;
        image = "pihole/pihole";
        volumes = [
          "${cfg.persistanceRoot}/etc/pihole:/etc/pihole"
          "${cfg.persistanceRoot}/etc/dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = ["--network=host" "--cap-add=NET_ADMIN"];
        environment = {
          PIHOLE_GID = "${toString config.users.groups.pihole.gid}";
          PIHOLE_UID = "${toString config.users.users.pihole.uid}";

          # check https://docs.pi-hole.net/docker/upgrading/v5-v6/ for the lists of options
          # to use google DNS, use:
          # FTLCONF_dns_upstreams = "127.0.0.1#5335;8.8.8.8;8.8.4.4";
          FTLCONF_webserver_port = "8080,[::]:8080";
          FTLCONF_dns_upstreams = "127.0.0.1#5335";
          FTLCONF_dns_listeningMode = "all";
          FTLCONF_webserver_api_password = "password";
          TZ = "${userdata.timeZone}";
        };
      };
    };
  };
}
