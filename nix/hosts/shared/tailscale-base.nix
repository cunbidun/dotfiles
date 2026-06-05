{ config, pkgs, lib, ... }:
let
  getToken = ''
    CURL="${pkgs.curl}/bin/curl"
    JQ="${pkgs.jq}/bin/jq"
    TOKEN=$($CURL -sf \
      -d "client_id=$(cat ${config.sops.secrets.tailscale_client_id.path})" \
      -d "client_secret=$(cat ${config.sops.secrets.tailscale_client_secret.path})" \
      "https://api.tailscale.com/api/v2/oauth/token" | $JQ -r '.access_token')
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
      echo "ERROR: failed to obtain OAuth access token"
      exit 1
    fi
  '';

  authKeyScript = pkgs.writeShellScript "tailscale-authkey-gen" ''
    ${getToken}

    KEY=$($CURL -sf -X POST \
      "https://api.tailscale.com/api/v2/tailnet/-/keys" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"capabilities":{"devices":{"create":{"reusable":true,"ephemeral":false,"tags":["tag:server"]}}},"expirySeconds":3600}' \
      | $JQ -r '.key')

    if [ -z "$KEY" ] || [ "$KEY" = "null" ]; then
      echo "ERROR: failed to generate auth key"
      exit 1
    fi

    echo -n "$KEY" > /run/tailscale-authkey
    chmod 600 /run/tailscale-authkey
    echo "OK: auth key written to /run/tailscale-authkey"
  '';
in
{
  sops.secrets.tailscale_client_id = {};
  sops.secrets.tailscale_client_secret = {};

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = "/run/tailscale-authkey";
    extraUpFlags = [ "--advertise-tags=tag:server" ];
  };

  systemd.services.tailscale-authkey-gen = {
    description = "Generate Tailscale auth key via OAuth";
    before = [ "tailscaled-autoconnect.service" ];
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "tailscaled-autoconnect.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = authKeyScript;
    };
  };
}
