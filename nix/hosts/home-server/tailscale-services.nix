{ config, pkgs, lib, userdata, ... }:
let
  tailnet = userdata.tailnetDomain;

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

  # ── ACL ──────────────────────────────────────────────────────────────────
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
    autoApprovers = {
      services = lib.genAttrs (builtins.attrNames serveRoutes) (_: ["tag:server"]);
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

    LOCAL_NORM=$($JQ -Sc '{grants,ssh,tagOwners,autoApprovers}' ${aclFile})
    REMOTE_NORM=$(echo "$REMOTE" | $JQ -Sc '{grants,ssh,tagOwners,autoApprovers}')

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
    "svc:files"         = { port = 16000; };
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
    DEVICE_ID=$(${pkgs.tailscale}/bin/tailscale status --json | $JQ -r '.Self.ID')
    if [ -z "$DEVICE_ID" ] || [ "$DEVICE_ID" = "null" ]; then
      echo "ERROR: failed to determine local Tailscale device ID"
      exit 1
    fi

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

      $CURL -sf -X POST "$BASE/${svc}/device/$DEVICE_ID/approved" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"approved":true}' \
        && echo "OK (approved): ${svc}" || echo "WARN: failed to approve ${svc} for $DEVICE_ID"
    '') (builtins.attrNames serveRoutes)}
  '';
in
{
  imports = [ ../shared/tailscale-base.nix ];

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
    after = [
      "tailscaled.service"
      "tailscaled-autoconnect.service"
      "network-online.target"
      "tailscale-acl-sync.service"
      "tailscale-services-sync.service"
    ];
    wants = [
      "network-online.target"
      "tailscale-acl-sync.service"
      "tailscale-services-sync.service"
    ];
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
    after = [ "network-online.target" "sops-nix.service" "tailscale-acl-sync.service" ];
    wants = [ "network-online.target" "tailscale-acl-sync.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = servicesSyncScript;
    };
  };
}
