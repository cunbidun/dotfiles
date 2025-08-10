{userdata, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = userdata.authorizedKeys;
  system.stateVersion = "25.05";
}
