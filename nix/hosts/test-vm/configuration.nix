{
  inputs,
  hostName,
  pkgs,
  userdata,
  lib,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../shared/nix-config.nix
    ../shared/sops-service.nix
    ../shared/tailscale-base.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  networking.hostName = hostName;
  networking.networkmanager.enable = true;

  # This node's single tailnet identity tag (owned + authorized by the ACL in
  # home-server/tailscale-services.nix).
  myTailscale.tags = [ userdata.tailnetTags.testVm ];

  time.timeZone = userdata.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.name;
    shell = pkgs.zsh;
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  programs.zsh.enable = true;

  # QEMU guest agent for better VM integration
  services.qemuGuest.enable = true;

  sops = {
    defaultSopsFile = ../../../secrets/system.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
    secrets.github_read_only_token = {
      owner = userdata.username;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    kitty.terminfo
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.05";
}
