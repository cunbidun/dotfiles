{
  config,
  userdata,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./9router.nix
    ./home-page.nix
    ./immich.nix
    ./tailscale-services.nix
    ../shared/nix-config.nix
    ../shared/common.nix
    ../shared/user-secrets.nix
    ../shared/monitoring.nix
    inputs.sops-nix.nixosModules.sops
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "home-server";
  networking.networkmanager.enable = true;

  # User groups specific to home-server
  users.users.${userdata.username}.extraGroups = [
    "wheel"
    "networkmanager"
    "docker"
  ];

  # SSH specific to home-server
  services.openssh.settings.PermitRootLogin = "yes";

  # home-server specific: act as a subnet/exit-node client
  services.tailscale.useRoutingFeatures = "client";

  sops = {
    defaultSopsFile = ../../../secrets/system.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
  };

  # File sharing over Tailscale.
  services.samba = {
    enable = true;
    openFirewall = false;
    settings = {
      global = {
        "map to guest" = "Bad User";
        "server min protocol" = "SMB3";
      };

      shared = {
        path = "/srv/storage/shared";
        browsable = "yes";
        writable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "guest only" = "yes";
        "force user" = userdata.username;
        "force group" = "users";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/storage/shared 0775 ${userdata.username} users -"
    "d /srv/storage/immich 0750 immich immich -"
  ];

  users.users.nextcloud.extraGroups = ["users"];

  services.nextcloud = {
    enable = true;
    hostName = "files.${userdata.tailnetDomain}";
    https = true;
    package = pkgs.nextcloud32;
    configureRedis = true;
    enableImagemagick = true;
    imaginary.enable = true;
    maxUploadSize = "10G";
    settings = {
      default_phone_region = "US";
      overwriteprotocol = "https";
      trusted_proxies = ["127.0.0.1" "::1"];
    };
    config = {
      dbtype = "sqlite";
      adminuser = userdata.username;
      adminpassFile = "/var/lib/nextcloud/adminpass";
    };
  };

  services.nginx.virtualHosts."files.${userdata.tailnetDomain}".listen = lib.mkForce [
    {
      addr = "127.0.0.1";
      port = 16000;
      ssl = false;
    }
  ];

  systemd.services.nextcloud-adminpass-init = {
    description = "Create Nextcloud admin password file";
    before = ["nextcloud-setup.service"];
    wantedBy = ["nextcloud-setup.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nextcloud-adminpass-init" ''
        set -eu
        install -d -m 0750 -o nextcloud -g nextcloud /var/lib/nextcloud
        printf '%s\n' '123456' > /var/lib/nextcloud/adminpass
        chown nextcloud:nextcloud /var/lib/nextcloud/adminpass
        chmod 0600 /var/lib/nextcloud/adminpass
      '';
    };
  };

  systemd.services.nextcloud-setup = {
    after = ["nextcloud-adminpass-init.service"];
    requires = ["nextcloud-adminpass-init.service"];
  };

  systemd.services.nextcloud-password-reset = {
    description = "Set Nextcloud admin password";
    after = ["nextcloud-setup.service"];
    requires = ["nextcloud-setup.service"];
    wantedBy = ["multi-user.target"];
    path = [config.services.nextcloud.occ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      Environment = "NC_PASS=123456";
      ExecStart = pkgs.writeShellScript "nextcloud-password-reset" ''
        set -eu
        nextcloud-occ app:disable password_policy || true
        nextcloud-occ user:resetpassword --password-from-env ${lib.escapeShellArg userdata.username}
      '';
    };
  };

  systemd.services.nextcloud-shared-storage = {
    description = "Mount shared storage in Nextcloud";
    after = ["nextcloud-password-reset.service"];
    requires = ["nextcloud-password-reset.service"];
    wantedBy = ["multi-user.target"];
    path = [config.services.nextcloud.occ pkgs.jq];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      ExecStart = pkgs.writeShellScript "nextcloud-shared-storage" ''
        set -eu

        nextcloud-occ app:enable files_external || true

        if ! nextcloud-occ files_external:list ${lib.escapeShellArg userdata.username} --output=json \
          | jq -e '.[] | select(.mount_point == "/Shared" and .configuration.datadir == "/srv/storage/shared")' >/dev/null; then
          nextcloud-occ files_external:create Shared local null::null \
            --user ${lib.escapeShellArg userdata.username} \
            --config datadir=/srv/storage/shared
        fi

        nextcloud-occ files:scan --path=/${lib.escapeShellArg userdata.username}/files/Shared
      '';
    };
  };

  # Taskwarrior 3 sync backend (TaskChampion server)
  services.taskchampion-sync-server = {
    enable = true;
    host = "0.0.0.0";
    port = 10222;
    # Leave unrestricted for now; access control can be tightened by allowClientIds.
    allowClientIds = [];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
  };

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    openFirewall = false;
    mediaLocation = "/srv/storage/immich";
    settings.server.externalDomain = "https://photos.${userdata.tailnetDomain}";
  };


  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = ["--volumes"];
  };

  # docker system prune doesn't cover build cache — prune it separately
  systemd.services.docker-builder-prune = {
    description = "Prune docker build cache";
    after = ["docker.service"];
    requires = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker builder prune -af";
    };
  };
  systemd.timers.docker-builder-prune = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # nix-gc only collects unreferenced paths; old system generations are GC roots
  # and pin their closures until explicitly deleted — do that first
  systemd.services.nix-gc.serviceConfig.ExecStartPre =
    "${pkgs.nix}/bin/nix-env --delete-generations --profile /nix/var/nix/profiles/system +3";

  # ── Monitoring: Prometheus + Grafana ─────────────────────────────────────
  services.prometheus = {
    enable = true;
    port = 9090;
    retentionTime = "30d";
      scrapeConfigs = [
        {
          job_name = "node";
          scrape_interval = "15s";
          static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels.nodename = "home-server";
          }
          {
            targets = [ "100.71.251.100:9100" ];
            labels.nodename = "nixos";
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3010;
      };
      security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
      # Disable auth for LAN/Tailscale-only access
      "auth.anonymous" = {
        enabled = true;
        org_role = "Admin";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
          jsonData = {
            scrapeInterval = "15s";
          };
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/etc/grafana/dashboards";
        }
      ];
    };
  };

  # Node Exporter Full dashboard patched with single $host variable (nodename-based)
  environment.etc."grafana/dashboards/node-exporter-full.json".source =
    let
      raw = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/latest/download";
        sha256 = "11hrll7fm626ikbva5md4gm0rca537vp4xsxa9sxl1pk15s6nk0q";
      };

      patchScript = pkgs.writeText "patch-dashboard.py" ''
import json, re, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

for v in data["templating"]["list"]:
    if v["name"] == "ds_prometheus":
        v["current"] = {"text": "-- Default --", "value": "default"}

data["templating"]["list"] = [
    v for v in data["templating"]["list"] if v["name"] == "ds_prometheus"
]
data["templating"]["list"].append({
    "name": "host",
    "type": "query",
    "query": {"query": "label_values(node_uname_info, nodename)",
              "refId": "Prometheus-host-Variable-Query"},
    "current": {"text": "home-server", "value": "home-server"},
    "includeAll": False,
    "multi": False,
    "sort": 1,
    "refresh": 2,
    "hide": 0,
})

def patch_query(q):
    pat = r"instance=\"\$node\"\s*,?\s*job=\"\$job\""
    repl = "nodename=\"$host\""
    return re.sub(pat, repl, q)

for panel in data.get("panels", []):
    for target in panel.get("targets", []):
        if "expr" in target:
            target["expr"] = patch_query(target["expr"])
    for subpanel in panel.get("panels", []):
        for target in subpanel.get("targets", []):
            if "expr" in target:
                target["expr"] = patch_query(target["expr"])

with open(sys.argv[2], "w") as f:
    json.dump(data, f, indent=2)
      '';
    in
    pkgs.runCommand "node-exporter-full-patched.json" { buildInputs = [ pkgs.python3 ]; } ''
      python3 ${patchScript} ${raw} $out
    '';
  environment.systemPackages = with pkgs; [
    kitty.terminfo
  ];

  # System state version
  system.stateVersion = "25.05";
}
