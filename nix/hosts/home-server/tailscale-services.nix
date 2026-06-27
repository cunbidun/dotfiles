{ config, pkgs, lib, userdata, ... }:
let
  tailnet = userdata.tailnetDomain;

  tsLib = import ../shared/tailscale-lib.nix { inherit pkgs config; };
  inherit (tsLib) getToken curl jq;
  ts = "${pkgs.tailscale}/bin/tailscale";

  # ── Tags ──────────────────────────────────────────────────────────────────
  # Each host carries exactly ONE identity tag, all sourced from userdata so the
  # literals live in exactly one place. `serverTags` is every host tag (used
  # where a rule applies to all servers); `homeServerTag` is just this node.
  homeServerTag = userdata.tailnetTags.homeServer;
  serverTags    = builtins.attrValues userdata.tailnetTags;

  # ── ACL ──────────────────────────────────────────────────────────────────
  acl = {
    groups = {
      # Limited tailnet guests. Add them in the Tailscale admin console as
      # plain Members (NOT Admin/Owner) so they never see the admin console.
      "group:guests" = [ "phamtuanquang912002@gmail.com" ];
    };

    grants = [
      # You (Owner/Admins) and all of your own devices: full access.
      { src = ["autogroup:owner" "autogroup:admin"]; dst = ["*"]; ip = ["*"]; }
      # The only outbound tailnet flow a server initiates: Prometheus on
      # home-server scraping node_exporter (tcp:9100) on the hosts it monitors
      # (see shared/monitoring.nix). Source is home-server alone (test-vm never
      # scrapes); dst stays `*` because a scrape target — the `nixos` desktop —
      # is an untagged personal device, so no host tag would match it.
      { src = [homeServerTag]; dst = ["*"]; ip = ["tcp:9100"]; }
      # Guests: SSH to the home-server (tcp 22) and the ai-proxy service only.
      # Because grants also drive visibility, these are the ONLY things a guest
      # sees in their tailnet — every other machine and service stays hidden.
      { src = ["group:guests"]; dst = [homeServerTag]; ip = ["tcp:22"]; }
      { src = ["group:guests"]; dst = ["svc:ai-proxy"]; ip = ["tcp:443"]; }
    ];

    ssh = [
      # You (Owner/Admins): full SSH incl. root into your tagged servers. MUST
      # stay `accept` (not `check`) so non-interactive
      # `nixos-rebuild --target-host root@home-server` deploys keep working.
      # `autogroup:admin` excludes guests (they are plain Members). Admin access
      # to your own untagged devices is handled by the `check` rule below
      # (Tailscale evaluates `check` before `accept`, so listing `autogroup:self`
      # here would be dead config — the check rule wins for self anyway).
      {
        action = "accept";
        src    = ["autogroup:admin"];
        dst    = serverTags;
        users  = ["autogroup:nonroot" "root"];
      }
      # Members: SSH into devices they own. This can never reach the home-server
      # regardless of who owns what — home-server is tagged, and tagged devices
      # are never part of any user's `autogroup:self`.
      {
        action = "check";
        src    = ["autogroup:member"];
        dst    = ["autogroup:self"];
        users  = ["autogroup:nonroot" "root"];
      }
      # Guests: SSH into the home-server ONLY as the unprivileged `biduncun`
      # account. Tailscale refuses any other login (including root).
      {
        action = "accept";
        src    = ["group:guests"];
        dst    = [homeServerTag];
        users  = ["biduncun"];
      }
    ];

    tagOwners = lib.genAttrs serverTags (_: ["autogroup:owner"]);
    autoApprovers = {
      # Only the home-server publishes these services, so only it may
      # auto-approve them (not every host tag, e.g. test-vm's tag:test-vm).
      services = lib.genAttrs (builtins.attrNames serveRoutes) (_: [homeServerTag]);
    };
  };

  aclFile = pkgs.writeText "tailscale-acl.json" (builtins.toJSON acl);

  aclSyncScript = pkgs.writeShellScript "tailscale-acl-sync" ''
    ${getToken}

    REMOTE=$(${curl} -sf \
      -H "Authorization: Bearer $TOKEN" \
      -H "Accept: application/json" \
      "https://api.tailscale.com/api/v2/tailnet/-/acl")
    if [ $? -ne 0 ]; then
      echo "WARN: failed to fetch remote ACL"
      exit 1
    fi

    # Compare only the keys this module actually manages, derived from the local
    # ACL itself (not a hardcoded list) so adding e.g. `hosts`/`nodeAttrs` later
    # is picked up automatically instead of being silently never pushed. The
    # remote is projected onto our key set, dropping fields Tailscale maintains
    # on its own (tests, derived defaults) that we don't want to diff against.
    LOCAL_KEYS=$(${jq} -Sc 'keys' ${aclFile})
    LOCAL_NORM=$(${jq} -Sc . ${aclFile})
    REMOTE_NORM=$(printf '%s' "$REMOTE" | ${jq} -Sc \
      --argjson keys "$LOCAL_KEYS" \
      'with_entries(select(.key as $k | $keys | index($k) != null))')

    if [ "$LOCAL_NORM" = "$REMOTE_NORM" ]; then
      echo "OK: ACL unchanged, skipping"
    else
      echo "ACL differs, syncing..."
      ${curl} -sf -X POST \
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
    "svc:photos"        = { port = 2283;  };
    "svc:monitoring"    = { port = 3010;  };
  };

  serveScript = pkgs.writeShellScript "tailscale-serve-apply" ''
    # Machine-level: hub at home-server.${tailnet}
    ${ts} serve --bg --https=443 http://127.0.0.1:3001 2>/dev/null \
      && echo "OK: machine-level serve"

    # Service-level: one command per service, idempotent
    ${lib.concatMapStrings (svc: let cfg = serveRoutes.${svc}; in ''
      ${ts} serve --service=${svc} --bg --https=443 http://127.0.0.1:${toString cfg.port} 2>/dev/null \
        && echo "OK: ${svc}"
    '') (builtins.attrNames serveRoutes)}
  '';

  # ── Service definitions ───────────────────────────────────────────────────
  servicesSyncScript = pkgs.writeShellScript "tailscale-services-sync" ''
    ${getToken}
    BASE="https://api.tailscale.com/api/v2/tailnet/-/services"
    DEVICE_ID=$(${ts} status --json | ${jq} -r '.Self.ID')
    if [ -z "$DEVICE_ID" ] || [ "$DEVICE_ID" = "null" ]; then
      echo "ERROR: failed to determine local Tailscale device ID"
      exit 1
    fi

    ${lib.concatMapStrings (svc: ''
      echo "Syncing ${svc}..."
      EXISTING=$(${curl} -sf -H "Authorization: Bearer $TOKEN" "$BASE/${svc}")
      if [ $? -eq 0 ]; then
        ADDRS=$(echo "$EXISTING" | ${jq} '.addrs')
        ${curl} -sf -X PUT "$BASE/${svc}" \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"name\":\"${svc}\",\"ports\":[\"tcp:443\"],\"addrs\":$ADDRS}" \
          && echo "OK (updated): ${svc}" || echo "WARN: failed to update ${svc}"
      else
        ${curl} -sf -X PUT "$BASE/${svc}" \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '{"name":"${svc}","ports":["tcp:443"]}' \
          && echo "OK (created): ${svc}" || echo "WARN: failed to create ${svc}"
      fi

      ${curl} -sf -X POST "$BASE/${svc}/device/$DEVICE_ID/approved" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"approved":true}' \
        && echo "OK (approved): ${svc}" || echo "WARN: failed to approve ${svc} for $DEVICE_ID"
    '') (builtins.attrNames serveRoutes)}
  '';
in
{
  imports = [
    ../shared/sops-service.nix
    ../shared/tailscale-base.nix
  ];

  # One identity tag for this node: `tag:home-server` (so guest ACLs can target
  # ONLY home-server, not other hosts like test-vm). Rules that should apply to
  # every server list `serverTags` (admin SSH, tagOwners) above. Also enable
  # Tailscale SSH so the `users = ["biduncun"]` / no-root mapping is enforced
  # by Tailscale.
  myTailscale.tags = [ homeServerTag ];
  myTailscale.ssh = true;

  # Force every sync oneshot to re-run on each nixos-rebuild switch. They are
  # RemainAfterExit units, so without this they'd only re-run when their unit
  # text changed — which is why serve/services didn't re-converge after the
  # device was recreated. All three are idempotent; systemd orders them by their
  # After= deps (serve-apply last). `|| true` keeps a failed sync from aborting
  # the switch.
  system.activationScripts.tailscale-sync = {
    text = ''
      ${pkgs.systemd}/bin/systemctl restart \
        tailscale-acl-sync.service \
        tailscale-services-sync.service \
        tailscale-serve-apply.service || true
    '';
  };

  # The auth key (created in tailscale-base.nix) may carry tags that only
  # become valid once the ACL declares their tagOwners. Order key generation
  # after the ACL sync so minting a key for a brand-new tag never races the
  # policy push (which otherwise fails key creation on a from-scratch deploy).
  systemd.services.tailscale-authkey-gen = {
    after = [ "tailscale-acl-sync.service" ];
    wants = [ "tailscale-acl-sync.service" ];
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
