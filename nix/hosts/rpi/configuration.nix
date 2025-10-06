{
  config,
  userdata,
  pkgs,
  lib,
  ...
}: {
  imports = [./pihole.nix];
  users.users = {
    ${userdata.username} = {
      isNormalUser = true;
      description = userdata.name;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "input"
        "i2c"
        "docker"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
    };

    root = {
      openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
    };
  };

  security = {
    polkit.enable = true;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  system.stateVersion = config.system.nixos.release;

  time.timeZone = userdata.timeZone;

  networking = {
    hostName = "rpi5";
    useNetworkd = true;
    firewall.allowedUDPPorts = [5353];
    wireless.enable = false;
    wireless.iwd = {
      enable = true;
      settings = {
        Network = {
          EnableIPv6 = true;
          RoutePriorityOffset = 300;
        };
        Settings.AutoConnect = true;
      };
    };
  };

  systemd.network.networks = {
    "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
    "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
  };

  systemd.services = {
    systemd-networkd.stopIfChanged = false;
    systemd-resolved.stopIfChanged = false;
  };

  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  system.nixos.tags = [
    "raspberry-pi-5"
    config.boot.loader.raspberryPi.bootloader
    config.boot.kernelPackages.kernel.version
  ];

  services.tailscale = {
    enable = true;
  };

  services.pihole = {
    # to set password:
    # sudo podman exec -it pihole -- /bin/bash and then run `pihole setpassword <password>`
    # go to https://mynetworksettings.com/#/adv/network/networkconnections/broadsettings/WAN1 to set upstream DNS servers
    enable = true;
    serverIp = "192.168.1.165"; # Pi-Hole IP
  };
  services.resolved = {
    enable = false;
  };
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  programs.zsh.enable = true;
}
