{
  lib,
  pkgs,
  config,
  userdata,
  ...
}:
with lib; let
  cfg = config.services.pihole;
in {
  options.services.pihole = {
    enable = mkEnableOption "pihole service";
    serverIp = mkOption {
      type = types.str;
      description = "Address Pi-hole listens on";
    };
    persistanceRoot = mkOption {
      type = types.str;
      default = "/opt/pihole/etc";
    };
  };

  config = mkIf cfg.enable {
    services.unbound = {
      enable = true;
      settings = {
        server = {
          # Listen only on loopback; Pi-hole (host network) will hit 127.0.0.1#5335
          interface = ["127.0.0.1" "::1"];
          port = 5335;
          prefetch = true;
          access-control = [
            "127.0.0.0/8 allow"
          ];
        };
      };
    };

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

    systemd.tmpfiles.rules = [
      "d ${cfg.persistanceRoot} 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc/pihole 0755 pihole pihole -"
      "d ${cfg.persistanceRoot}/etc/dnsmasq.d 0755 pihole pihole -"
    ];

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
          FTLCONF_dns_upstreams = "127.0.0.1#5335";
          FTLCONF_dns_listeningMode = "all";
          FTLCONF_webserver_api_password = "password";
          TZ = "${userdata.timeZone}";
        };
      };
    };
  };
}
