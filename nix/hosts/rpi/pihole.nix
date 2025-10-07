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
      default = "/var/log/pihole";
    };
  };

  config = mkIf cfg.enable {
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
        ports = [
          "0.0.0.0:53:53/tcp"
          "0.0.0.0:53:53/udp"
          "${cfg.serverIp}:9080:80/tcp"
        ];
        environment = {
          PIHOLE_GID = "${toString config.users.groups.pihole.gid}";
          PIHOLE_UID = "${toString config.users.users.pihole.uid}";
          TZ = "${userdata.timeZone}";
        };
      };
    };
  };
}
