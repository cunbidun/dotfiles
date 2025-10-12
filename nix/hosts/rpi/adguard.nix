{ lib, pkgs, config, ... }:
with lib;

let
  tailHost = "${config.networking.hostName}.tail9b4f4d.ts.net";
  certDir  = "/var/lib/tailscale/certs";
  certFile = "${certDir}/cert.pem";
  keyFile  = "${certDir}/key.pem";
in
{
  options.services.adguard = {
    enable = mkEnableOption "AdGuard Home DNS filtering service with Tailscale TLS integration";
    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/adguardhome";
      description = "Persistent directory for AdGuard Home data.";
    };
  };

  config = mkIf config.services.adguard.enable {

    #################################################
    # Tailscale certificate automation (daily renew)
    #################################################
    systemd.tmpfiles.rules = [
      "d /var/lib/tailscale 0750 root root -"
      "d ${certDir} 0750 root root -"
    ];

    systemd.services."tailscale-cert" = {
      description = "Fetch/refresh Tailscale TLS cert for ${tailHost}";
      after = [ "network-online.target" "tailscale.service" ];
      wants = [ "network-online.target" ];
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
        chmod 0640 ${certFile} ${keyFile}
      '';
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers."tailscale-cert" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    ###########################################
    # AdGuard Home DNS + HTTPS (built-in TLS)
    ###########################################
    services.adguardhome = {
      enable = true;
      openFirewall = true;
      settings = {
        http = {
          address = "0.0.0.0";
          port = 80; # optional redirect
        };
        tls = {
          enabled = true;
          force_https = true;
          certificate_chain = certFile;
          private_key       = keyFile;
        };
        dns = {
          bind_hosts = [ "0.0.0.0" "::" ];
          port = 53;
          # privacy-friendly DoH upstreams
          upstream_dns = [
            "https://cloudflare-dns.com/dns-query"
            "https://dns.quad9.net/dns-query"
          ];
          bootstrap_dns = [ "1.1.1.1" "9.9.9.9" ];
          enable_dnssec = true;
          edns_client_subnet = { enabled = false; };
          cache_size = 128;
          ratelimit = 0;
          blocking_mode = "default";
        };
        filters = [
          { name = "AdGuard Base"; url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"; enabled = true; }
          { name = "StevenBlack";  url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";   enabled = true; }
          { name = "EasyPrivacy";  url = "https://v.firebog.net/hosts/Easyprivacy.txt";                         enabled = true; }
        ];
        querylog_enabled = true;
        statistics = { enabled = true; interval = "24h"; };
      };
    };
  };
}
