{ config, pkgs, lib, userdata, ... }:
let
  tailnet = userdata.tailnetDomain;

  # Shared helper: exchange OAuth client credentials for a short-lived access token
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

  # ── Auth key generation ───────────────────────────────────────────────────
  # Generates a short-lived auth key at boot via OAuth. Written to /run (tmpfs)
  # — never touches disk or git. Replaces the static home_server_key in sops.
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

  # ── ACL ──────────────────────────────────────────────────────────────────
  # Source of truth for the tailnet policy. Synced to control plane on every switch.
  acl = {
    grants = [
      { src = ["*"]; dst = ["*"]; ip = ["*"]; }
    ];
    ssh = [
      {
        action = "check";
        src    = ["autogroup:member"];
        dst    = ["autogroup:self"];
        users  = ["autogroup:nonroot" "root"];
      }
    ];
    tagOwners = {
      "tag:server" = ["autogroup:owner"];
    };
  };

  aclFile = pkgs.writeText "tailscale-acl.json" (builtins.toJSON acl);

  aclSyncScript = pkgs.writeShellScript "tailscale-acl-sync" ''
    ${getToken}

    REMOTE=$($CURL -sf \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" \
      "https://api.tailscale.com/api/v2/tailnet/-/acl")
    if [ $? -ne 0 ]; then
      echo "WARN: failed to fetch remote ACL"
      exit 1
    fi

    LOCAL_NORM=$($JQ -Sc '{grants,ssh,tagOwners}' ${aclFile})
    REMOTE_NORM=$(echo "$REMOTE" | $JQ -Sc '{grants,ssh,tagOwners}')

    if [ "$LOCAL_NORM" = "$REMOTE_NORM" ]; then
      echo "OK: ACL unchanged, skipping"
    else
      echo "ACL differs, syncing..."
      $CURL -sf -X POST \
        "https://api.tailscale.com/api/v2/tailnet/-/acl" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d @${aclFile} \
        && echo "OK: ACL synced" \
        || echo "WARN: ACL sync failed"
    fi
  '';

  # ── Serve routes ─────────────────────────────────────────────────────────
  serveRoutes = {
    "svc:spending"      = { port = 3002;  };
    "svc:ai-proxy"      = { port = 20128; };
    "svc:self-learning" = { port = 8765;  };
    "svc:opencode"      = { port = 10300; };
  };

  serveScript = pkgs.writeShellScript "tailscale-serve-apply" ''
    TS="${pkgs.tailscale}/bin/tailscale"

    # Machine-level: hub at home-server.${tailnet}
    $TS serve --bg --https=443 http://127.0.0.1:3001 2>/dev/null \
      && echo "OK: machine-level serve"

    # Service-level: one command per service, idempotent
    ${lib.concatMapStrings (svc: let cfg = serveRoutes.${svc}; in ''
      $TS serve --service=${svc} --bg --https=443 http://127.0.0.1:${toString cfg.port} 2>/dev/null \
        && echo "OK: ${svc}"
    '') (builtins.attrNames serveRoutes)}
  '';

  # ── Service definitions ───────────────────────────────────────────────────
  servicesSyncScript = pkgs.writeShellScript "tailscale-services-sync" ''
    ${getToken}
    BASE="https://api.tailscale.com/api/v2/tailnet/-/services"

    ${lib.concatMapStrings (svc: ''
      echo "Syncing ${svc}..."
      EXISTING=$($CURL -sf -H "Authorization: Bearer $TOKEN" "$BASE/${svc}")
      if [ $? -eq 0 ]; then
        ADDRS=$(echo "$EXISTING" | $JQ '.addrs')
        $CURL -sf -X PUT "$BASE/${svc}" \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"name\":\"${svc}\",\"ports\":[\"tcp:443\"],\"addrs\":$ADDRS}" \
          && echo "OK (updated): ${svc}" || echo "WARN: failed to update ${svc}"
      else
        $CURL -sf -X PUT "$BASE/${svc}" \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '{"name":"${svc}","ports":["tcp:443"]}' \
          && echo "OK (created): ${svc}" || echo "WARN: failed to create ${svc}"
      fi
    '') (builtins.attrNames serveRoutes)}
  '';
in
{
  sops.secrets.tailscale_client_id = {};
  sops.secrets.tailscale_client_secret = {};

  # Generate a fresh auth key before tailscaled-autoconnect runs
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

  # Always restart on every nixos-rebuild switch
  system.activationScripts.tailscale-acl-sync = {
    text = "systemctl restart tailscale-acl-sync || true";
  };

  # Sync tailnet ACL/policy to control plane
  systemd.services.tailscale-acl-sync = {
    description = "Sync Tailscale ACL policy to control plane";
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = aclSyncScript;
    };
  };

  # Apply serve routing on every boot/switch
  systemd.services.tailscale-serve-apply = {
    description = "Apply Tailscale serve routing config";
    after = [ "tailscaled.service" "tailscaled-autoconnect.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = serveScript;
    };
  };

  # Sync service definitions to Tailscale control plane
  systemd.services.tailscale-services-sync = {
    description = "Sync Tailscale Service definitions to control plane";
    after = [ "network-online.target" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = servicesSyncScript;
    };
  };
}
