{userdata, ...}: {
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [userdata.authorizedKeys];
}
