{userdata, ...}: {
  # 9router (the "ai-proxy" Tailscale service) runs as a rootless podman
  # container under the user's systemd manager; see ./9router-home.nix.
  # This module only provides the system-level prerequisites.

  users.users.${userdata.username} = {
    # Start the user manager at boot so the container runs without a login.
    linger = true;
    # Subordinate UID/GID ranges for rootless podman user namespaces.
    autoSubUidGidRange = true;
  };

  networking.firewall.allowedTCPPorts = [20128];
}
