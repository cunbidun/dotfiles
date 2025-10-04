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
