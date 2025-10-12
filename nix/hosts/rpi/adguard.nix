{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  options.services.adguard = {
    enable = mkEnableOption "AdGuard Home DNS filtering service";
    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/adguardhome";
      description = "Persistent directory for AdGuard Home data.";
    };
  };

  config = mkIf config.services.adguard.enable {
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

    ###########################################
    # AdGuard Home DNS + HTTPS (built-in TLS)
    ###########################################
    services.resolved = {
      enable = false;
    };
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      openFirewall = true;
      port = 80;
      settings = {
        dns = {
          bind_hosts = ["0.0.0.0" "::"];
          port = 53;
          upstream_dns = ["127.0.0.1:5335"];
          bootstrap_dns = ["127.0.0.1:5335"];
          enable_dnssec = true;
          edns_client_subnet = {enabled = false;};
          cache_size = 128;
          ratelimit = 0;
          blocking_mode = "default";
        };
        filters = [
          {
            name = "AdGuard Base";
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            enabled = true;
          }
          {
            name = "hagezi";
            url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
            enabled = true;
          }
        ];
        querylog_enabled = true;
        statistics = {
          enabled = true;
          interval = "24h";
        };
      };
    };
  };
}
