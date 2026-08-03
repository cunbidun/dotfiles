# ActivityWatch server role -- the host that stores and serves the data.
#
# Imported by home-server alone. Watcher hosts get ./default.nix instead, which
# runs watchers and no server; the two roles are deliberately not combinable, so
# there is exactly one datastore to back up and one URL to open.
{pkgs, ...}: let
  endpoint = import ./endpoint.nix;
in {
  services.activitywatch = {
    enable = true;
    package = pkgs.nixpkgs-stable.aw-server-rust;

    # No watchers here: a headless box has no window or idle activity worth
    # recording. --host 0.0.0.0 is what makes the server reachable from other
    # machines at all -- it otherwise binds loopback and every remote watcher
    # fails with a connection refused that only shows up as missing data.
    extraOptions = [
      "--host"
      "0.0.0.0"
      "--port"
      (toString endpoint.port)
    ];
  };
}
