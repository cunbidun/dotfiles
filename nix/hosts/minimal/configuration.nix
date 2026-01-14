# Minimal NixOS installer configuration for USB boot with SSH access
# For use with nixos-anywhere
{
  config,
  pkgs,
  userdata,
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # ISO image settings
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # Network - enable DHCP on all interfaces
  networking.hostName = "nixos-installer";
  networking.useDHCP = lib.mkDefault true;

  # Enable networkmanager for easier network setup
  networking.networkmanager.enable = true;

  # Enable SSH immediately on boot
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # Root user with SSH key
  users.users.root.openssh.authorizedKeys.keys = userdata.authorizedKeys;

  # Firewall - allow SSH
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [22];

  # Essential packages for installation and nixos-anywhere
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    tmux
    rsync
    parted
    gptfdisk
    cryptsetup
    # Useful for debugging
    pciutils
    usbutils
    ethtool
  ];

  # No password for root (SSH key only)
  users.users.root.initialHashedPassword = "";

  # System state version
  system.stateVersion = "25.05";
}
