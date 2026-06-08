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
    ./tailscale-services.nix
    ../shared/nix-config.nix
    ../shared/common.nix
    ../shared/user-secrets.nix
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
  ];

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
    description = "Create initial Nextcloud admin password file";
    before = ["nextcloud-setup.service"];
    wantedBy = ["nextcloud-setup.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nextcloud-adminpass-init" ''
        set -eu
        install -d -m 0750 -o nextcloud -g nextcloud /var/lib/nextcloud
        if [ ! -s /var/lib/nextcloud/adminpass ]; then
          umask 077
          ${pkgs.openssl}/bin/openssl rand -base64 48 > /var/lib/nextcloud/adminpass
        fi
        chown nextcloud:nextcloud /var/lib/nextcloud/adminpass
        chmod 0600 /var/lib/nextcloud/adminpass
      '';
    };
  };

  systemd.services.nextcloud-setup = {
    after = ["nextcloud-adminpass-init.service"];
    requires = ["nextcloud-adminpass-init.service"];
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

  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = ["--volumes"];
  };

  environment.systemPackages = with pkgs; [
    kitty.terminfo
  ];

  # System state version
  system.stateVersion = "25.05";
}
