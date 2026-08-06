# ActivityWatch server role -- the host that stores and serves the data.
#
# Imported by home-server alone. Watcher hosts get ./default.nix instead, which
# runs watchers and no server; the two roles are deliberately not combinable, so
# there is exactly one datastore to back up and one URL to open.
{
  pkgs,
  userdata,
  ...
}: let
  endpoint = import ./endpoint.nix;
in {
  # Derived data, so it lives with the datastore rather than with the watchers --
  # see the header of ./ios-mirror.nix.
  imports = [./ios-mirror.nix];

  services.activitywatch = {
    enable = true;
    package = pkgs.nixpkgs-stable.aw-server-rust;

    # No watchers here: a headless box has no window or idle activity worth
    # recording.
    settings = {
      # 0.0.0.0 is what makes the server reachable from other machines at all --
      # it otherwise binds loopback and every remote watcher fails with a
      # connection refused that surfaces only as missing data. Exposure is bounded
      # by the firewall, which trusts tailscale0 alone (see the host's
      # configuration.nix), so this is a tailnet-only listener.
      address = "0.0.0.0";
      inherit (endpoint) port;

      # aw-server-rust rejects any request carrying a cross-origin Origin header
      # with a bare 403 -- a DNS-rebinding guard that assumes the UI is always on
      # localhost. Browsing to this host directly therefore loads the page and
      # then fails every XHR behind it, so the names it is actually reached by
      # have to be named here. Localhost is always allowed, which is what the
      # desktop's proxy in ./default.nix relies on.
      cors = [
        "http://${endpoint.host}:${toString endpoint.port}"
        "http://${endpoint.host}.${userdata.tailnetDomain}:${toString endpoint.port}"
      ];
    };
  };
}
