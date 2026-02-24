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

  # Tailscale specific to home-server
  services.tailscale.useRoutingFeatures = "client";
  services.tailscale.openFirewall = true;

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

  # Docker specific settings
  virtualisation.docker.enableOnBoot = true;

  # System state version
  system.stateVersion = "25.05";
}
