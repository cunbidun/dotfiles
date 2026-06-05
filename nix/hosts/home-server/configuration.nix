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

  # Shared secrets used by Home Manager modules.
  sops = {
    defaultSopsFile = ../../../secrets/system.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
    secrets.github_read_only_token = {
      path = "/home/${userdata.username}/.config/opencode/github_read_only_token";
      owner = userdata.username;
      group = "users";
      mode = "0400";
    };
    secrets.ninerouter_api_key = {
      path = "/home/${userdata.username}/.config/opencode/ninerouter_api_key";
      owner = userdata.username;
      group = "users";
      mode = "0400";
    };
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

  environment.systemPackages = with pkgs; [
    kitty.terminfo
  ];

  # System state version
  system.stateVersion = "25.05";
}
