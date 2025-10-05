{
  config,
  userdata,
  pkgs,
  ...
}: {
  networking.hostName = "rpi5";
  networking.networkmanager.enable = true;
  system.nixos.tags = let
    cfg = config.boot.loader.raspberryPi;
  in [
    "raspberry-pi-${cfg.variant}"
    cfg.bootloader
    config.boot.kernelPackages.kernel.version
  ];
  boot = {
    loader.raspberryPi.firmwarePackage = pkgs.linuxAndFirmware.v6_6_31.raspberrypifw;
    loader.raspberryPi.bootloader = "kernel";
    kernelPackages = pkgs.linuxAndFirmware.v6_6_31.linuxPackages_rpi5;
  };

  system.stateVersion = "25.05";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.name;
    extraGroups = ["networkmanager" "wheel" "input" "i2c" "docker"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  programs.zsh.enable = true;
}
