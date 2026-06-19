# Shared Tailscale helpers, imported as a plain function (not a NixOS module)
# by both shared/tailscale-base.nix (auth-key generation) and
# home-server/tailscale-services.nix (ACL / serve / services sync) so the
# OAuth token logic lives in exactly one place.
#
#   let tsLib = import ./tailscale-lib.nix { inherit pkgs config; };
#   inherit (tsLib) getToken curl jq;
{ pkgs, config }:
let
  curl = "${pkgs.curl}/bin/curl";
  jq = "${pkgs.jq}/bin/jq";
in
{
  inherit curl jq;

  # Shell snippet: obtains a Tailscale OAuth access token into $TOKEN, aborting
  # the script if the request fails.
  #
  # Secrets are passed with curl's `@file` form (--data-urlencode) so the
  # client_id/client_secret are read straight from their sops files and never
  # appear in curl's argv — i.e. never in /proc/<pid>/cmdline, which any local
  # user (including unprivileged tailnet guests) could otherwise read mid-run.
  # The sops secrets are stored as `type:str` scalars with no trailing newline,
  # so the encoded bodies match what the `-d "name=$(cat …)"` form used to send.
  getToken = ''
    TOKEN=$(${curl} -sf \
      --data-urlencode "client_id@${config.sops.secrets.tailscale_client_id.path}" \
      --data-urlencode "client_secret@${config.sops.secrets.tailscale_client_secret.path}" \
      "https://api.tailscale.com/api/v2/oauth/token" | ${jq} -r '.access_token')
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
      echo "ERROR: failed to obtain OAuth access token"
      exit 1
    fi
  '';
}
