{ config, pkgs, lib, ... }:
let
  cfg = config.myTailscale;

  tsLib = import ./tailscale-lib.nix { inherit pkgs config; };
  inherit (tsLib) getToken curl jq;

  # Auth-key creation payload. The tags listed here are the only tags the
  # generated key is allowed to advertise, so they must be a superset of
  # whatever the node advertises via --advertise-tags below.
  createPayload = builtins.toJSON {
    capabilities.devices.create = {
      reusable = true;
      ephemeral = false;
      tags = cfg.tags;
    };
    expirySeconds = 3600;
  };

  authKeyScript = pkgs.writeShellScript "tailscale-authkey-gen" ''
    ${getToken}

    KEY=$(${curl} -sf -X POST \
      "https://api.tailscale.com/api/v2/tailnet/-/keys" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '${createPayload}' \
      | ${jq} -r '.key')

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
  options.myTailscale = {
    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # No default: every host declares its own identity tag (from
      # userdata.tailnetTags) so there is no shared/generic fallback tag.
      description = ''
        Tailscale ACL tags this node advertises. Also authorized on the
        generated auth key, so the node may register/re-register with them.
      '';
    };
    ssh = lib.mkEnableOption "Tailscale SSH server on this host";
  };

  config = {
    sops.secrets.tailscale_client_id = {};
    sops.secrets.tailscale_client_secret = {};

    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = "/run/tailscale-authkey";
      extraUpFlags =
        [ "--advertise-tags=${lib.concatStringsSep "," cfg.tags}" ]
        ++ lib.optional cfg.ssh "--ssh";
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
  };
}
