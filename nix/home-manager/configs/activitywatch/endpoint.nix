# The single ActivityWatch server for the whole tailnet, on home-server. Every
# watcher on every host posts here directly, so this pair is the only thing they
# all share -- hence a file of its own rather than the same literal copied into
# each watcher.
#
# Plain HTTP over the tailnet, deliberately: awatcher takes --host/--port with no
# scheme, so a `tailscale serve` HTTPS route in front of it would be unusable for
# the watchers that matter. WireGuard already encrypts the hop, and home-server's
# firewall trusts tailscale0 only (hosts/home-server/configuration.nix), so 5600
# is not reachable from the LAN.
#
# Consequence worth knowing: heartbeats are not buffered. While the tailnet is
# down, watchers lose that stretch of time rather than backfilling it.
{
  host = "home-server";
  port = 5600;
}
