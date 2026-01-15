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
