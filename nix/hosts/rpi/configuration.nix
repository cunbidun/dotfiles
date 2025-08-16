{
  config,
  userdata,
  ...
}: {
  networking.hostName = "rpi5";
  system.nixos.tags = let
    cfg = config.boot.loader.raspberryPi;
  in [
    "raspberry-pi-${cfg.variant}"
    cfg.bootloader
    config.boot.kernelPackages.kernel.version
  ];

  users.users.root.openssh.authorizedKeys.keys = userdata.authorizedKeys;
  system.stateVersion = "25.05";
}
