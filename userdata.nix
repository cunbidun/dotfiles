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
}
