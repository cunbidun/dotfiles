# Test VM Bootstrap

A QEMU/KVM VM for testing the 2-stage NixOS bootstrap flow without touching real hardware.

## Prerequisites

- KVM available (`/dev/kvm`)
- 1Password agent running (`~/.1password/agent.sock`)

---

## Stage 1: Install

**Start the installer VM** (builds ISO, creates disk, boots, waits for SSH):

```bash
nix run .#vm-start
```

**Deploy NixOS and reboot** into the installed system:

```bash
nix run .#vm-deploy
```

Expected: sops logs `cannot read keyfile '/var/lib/sops-nix/keys.txt'` — normal, no age key yet.

---

## Stage 2: Secrets + first switch

```bash
# Place age key from 1Password
SSH_AUTH_SOCK=~/.1password/agent.sock \
  op read "op://Private/SOPS Age Key/private key" | \
  SSH_AUTH_SOCK=~/.1password/agent.sock ssh \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p 2222 root@localhost \
    'install -d -m 700 /var/lib/sops-nix && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'

# Switch — sops decrypts secrets, tailscale joins the tailnet automatically
nix run .#switch -- test-vm
```

The VM is now on your tailnet as `test-vm`.

---

## Iterating

```bash
nix run .#switch -- test-vm
```

---

## Teardown

```bash
nix run .#vm-destroy
```

---

## How it works

| Step | What happens | Manual? |
|------|-------------|---------|
| `vm-start` | Build ISO → create disk → boot installer → wait for SSH | No |
| `vm-deploy` | nixos-anywhere → reboot into installed system | No |
| Place age key | `op read` → `/var/lib/sops-nix/keys.txt` on VM | Yes (one command) |
| `switch test-vm` | sops decrypts secrets, tailscale OAuth → auth key → tailnet join | No |
| Subsequent switches | Fully declarative | No |
