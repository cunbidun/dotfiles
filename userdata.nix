{
  username = "cunbidun";
  email = "cunbidun@gmail.com";
  name = "Duy Pham";
  timeZone = "America/New_York";
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYi6b9Qaa6hF5PXkaTinS131ESVKDkQTOWCcvD8JmZ3"
  ];
  tailnetDomain = "tail9b4f4d.ts.net";

  # One identity tag per tailnet host. Single source of truth: the ACL
  # (home-server/tailscale-services.nix) and each host's myTailscale.tags both
  # read from here, so a tag literal is never written twice.
  tailnetTags = {
    homeServer = "tag:home-server";
    testVm     = "tag:test-vm";
  };

  # Tailscale *device* names, independent of both the OS hostname and the
  # identity tag above — renaming a device in the admin console changes only
  # this. Anything addressing a host by its `<name>.<tailnetDomain>` FQDN reads
  # from here, so a rename is one edit instead of a hunt. Prefer a Tailscale
  # Service name (svc:*, see hosts/home-server/tailscale-services.nix) where one
  # exists; these are for protocols with no service in front of them, e.g. SSH.
  #
  # Devices and services share ONE `<name>.<tailnetDomain>` namespace, so a name
  # used here must not also be a service name (and vice versa): the loser gets
  # silently suffixed — `qandq` → `qandq-1` — and can then never hold a TLS cert
  # for the name it wanted. A name freed by deleting its holder stays reserved
  # for a while afterwards, so renaming onto it fails until that clears.
  tailnetDeviceNames = {
    homeServer = "home-server";
  };
}
