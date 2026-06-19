# Tailscale

The home-server is fully managed declaratively. Every `nixos-rebuild switch` applies
the desired state — no manual admin console steps needed after initial setup.

## Architecture

```text
home-server.<tailnet>.ts.net   → 127.0.0.1:3001   (hub, machine-level serve)
spending.<tailnet>.ts.net      → 127.0.0.1:3002   (Tailscale Service)
ai-proxy.<tailnet>.ts.net      → 127.0.0.1:20128  (Tailscale Service)
self-learning.<tailnet>.ts.net → 127.0.0.1:8765   (Tailscale Service)
opencode.<tailnet>.ts.net      → 127.0.0.1:10300  (Tailscale Service)
```

All HTTPS (port 443) with TLS termination by Tailscale. The hub uses the machine's
own hostname; the four apps use named Tailscale Services (`svc:*`) which get stable
VIPs and their own `*.<tailnet>.ts.net` hostnames.

## Nix Files

| File | What it manages |
|---|---|
| `nix/hosts/shared/common.nix` | `services.tailscale.enable = true` (all machines) |
| `nix/hosts/home-server/configuration.nix` | Auth key, `tag:server`, firewall |
| `nix/hosts/home-server/tailscale-services.nix` | ACL, serve routing, service definitions |

## What Runs on Switch

Three systemd oneshot units fire on every `nixos-rebuild switch`. All three are
`RemainAfterExit` oneshots, so a single `system.activationScripts.tailscale-sync`
force-restarts all of them on each switch — otherwise they'd only re-run when
their unit text changed (which is why serve/services failed to re-converge after
the device was recreated). They're idempotent, and systemd orders them by their
`After=` deps (serve-apply last).

**`tailscale-acl-sync`**
Fetches the remote ACL and compares it to the Nix-defined policy: the remote is
projected onto whatever keys the local `acl` attr set defines (not a hardcoded
list) and POSTed only if they differ, so new top-level ACL keys are picked up
automatically.

**`tailscale-serve-apply`**
Runs `tailscale serve --bg --https=443` for the hub and each service. Idempotent —
Tailscale accepts re-applying the same config without error.

**`tailscale-services-sync`**
Creates or updates the four `svc:*` definitions on Tailscale's control plane via
`PUT /api/v2/tailnet/-/services/{name}`. On update it preserves the existing `addrs`
(VIPs assigned by Tailscale).

## Secrets (`secrets/global.yaml`)

| Key | Used by | Expires |
|---|---|---|
| `home_server_key` | `authKeyFile` — device auth + `tag:server` on boot | 90-day max; fresh install only |
| `tailscale_client_id` | OAuth token exchange in sync scripts | Never |
| `tailscale_client_secret` | OAuth token exchange in sync scripts | Never |

The two OAuth credentials replace the old `tailscale_api_token` (which had a 90-day
expiry). Each sync script calls `POST /api/v2/oauth/token` with the client id + secret
to get a short-lived (1-hour) access token, then uses that for all API calls.

## ACL Policy

Defined as a Nix attr set in `tailscale-services.nix`:

```nix
acl = {
  grants    = [{ src = ["*"]; dst = ["*"]; ip = ["*"]; }];
  ssh       = [{ action = "check"; src = ["autogroup:member"];
                 dst = ["autogroup:self"]; users = ["autogroup:nonroot" "root"]; }];
  tagOwners = { "tag:server" = ["autogroup:owner"]; };
};
```

`tagOwners` is required — without it, `tailscale up --advertise-tags=tag:server`
is rejected by the control plane, which breaks Tailscale Services routing.

Any change made in the admin console web UI is overwritten on the next switch.

## Why `tag:server`

Tailscale Services requires tag-based machine identity (not personal/user identity).
The tag is applied on every boot via `extraUpFlags`. Personal auth is invalidated
when a tag is applied — hence the reusable auth key scoped to `tag:server`.

## Adding a New Service

1. Add an entry to `serveRoutes` in `tailscale-services.nix`:

   ```nix
   "svc:my-app" = { port = 1234; };
   ```

2. Run `nixos-rebuild switch` — the serve config and service definition are both
   applied automatically. No admin console steps needed.

## Non-Declarative Remainder

- `home_server_key` expiry: the auth key maxes out at 90 days. On a running machine
  this has no effect. Only matters if the machine is rebuilt from scratch with an
  expired key. Renew by generating a new reusable key in the admin console scoped to
  `tag:server`, updating `secrets/global.yaml` via sops, and switching.

- Tailscale **prefs on an already-registered node** (advertised tags, `--ssh`, …) are
  not reconciled by `nixos-rebuild`. NixOS's `tailscaled-autoconnect` only runs
  `tailscale up` when the node is logged out, so on a *running* node a flag change in
  Nix is a no-op until it re-authenticates. A from-scratch rebuild picks the new prefs
  up automatically; only **in-place** changes to a live node need a manual re-register:

  ```sh
  # run over the LAN — enabling --ssh reroutes the tailnet SSH path and would drop you
  ssh root@192.168.1.189
  tailscale up --authkey="$(cat /run/tailscale-authkey)" \
    --advertise-tags=tag:server,tag:home-server --ssh
  ```

  Re-registering can create a duplicate device (e.g. `home-server-1`) if the old one
  still holds the name; delete the stale device via the API and re-register to reclaim it.
