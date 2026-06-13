{ userdata, ... }: {
  # Expose node_exporter metrics so Prometheus on home-server can scrape them
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" "processes" ];
  };

  # Allow home-server to reach node_exporter over Tailscale
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ];
}
