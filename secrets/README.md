# Secrets Workflow

This directory holds the encrypted payloads that `sops-nix` decrypts during system or Home Manager activation. The files checked into Git **must remain encrypted**; bootstrap with the steps below before running any `nixos-rebuild` or `home-manager switch`.

The repo imports the [`opnix`](https://github.com/brizzbuzz/opnix) modules so the 1Password CLI fetches the Age key automatically during activation. You still need to create the 1Password item it references and unlock the desktop app/CLI before switching.

## 1Password + Age bootstrap

1. Ensure the 1Password desktop app is installed and unlocked. In Settings ➝ Developer, enable **Integrate with 1Password CLI** and **Enable SSH agent** (optional but recommended).
2. Install the CLI (`op`). On NixOS/Home Manager this happens automatically once the new configuration is applied, but you need it available locally for the initial setup (e.g. `nix shell nixpkgs#_1password-cli`).
3. Generate an Age key pair and capture the public half:
   ```bash
   nix shell nixpkgs#age -c age-keygen -o /tmp/sops-age.key
   cat /tmp/sops-age.key | grep "^# public key:" | cut -d' ' -f4 > age.pub
   ```
   Copy the private key block into a new 1Password item—for example `Infrastructure / SOPS Age Key`—and delete `/tmp/sops-age.key` afterwards.
4. Update `age.pub` in this directory with your generated public key (replace the placeholder value in the repo).
5. Create a 1Password item (by default `Infrastructure` vault → `SOPS Age Key` item → `private key` field) and paste the private key there so `opnix` can retrieve it.
   - Steps in the UI:
     1. Open 1Password Desktop (macOS, Windows, or Linux).
     2. In the sidebar pick the **Infrastructure** vault. If it doesn’t exist yet, click **+ New Vault**, name it “Infrastructure”, and select it.
     3. Click **+ New Item** (top-right) and choose **Secure Note** (any simple item works).
     4. Set the item title to **SOPS Age Key**.
     5. Click **Add more → New Field → Text**, and label the field exactly **private key**.
     6. Paste your Age private key (the `AGE-SECRET-KEY-…` line) into that field.
     7. Save the item.

     You can verify the CLI reference with `op read "op://Infrastructure/SOPS Age Key/private key"`; it should print the key.
6. Configure a 1Password service account token with `opnix token set -path /etc/opnix-token` (or adjust the path in `services.onepassword-secrets.tokenFile`). Until the package is in your system profile, run it via `nix run github:brizzbuzz/opnix -- token set -path /etc/opnix-token`.
   - Generate the token in the 1Password web UI under **Integrations → Service accounts** (shortcut: <https://my.1password.com/developer-tools/infrastructure-secrets/serviceaccount/P4S4XMF6I5HWJCYB6OIQSDQI2E>). Create a service account that has read access to the `Infrastructure` vault, copy the token shown once, and paste it into the CLI prompt.

## First-time switch

1. **Apply the configuration once** (even without secrets) to get the Opnix unit installed:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```
2. **Create the 1Password service account** (see step 6 above) and run:
   ```bash
   sudo opnix token set -path /etc/opnix-token
   ```
3. **Populate the Age key** via Opnix:
   ```bash
   sudo systemctl restart opnix-secrets.service
   ```
4. **Reapply** so `sops-nix` can decrypt using the key:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

## Encrypting the secret files

Create or update the file with `sops`:

- **Create a new encrypted file**
  ```bash
  sops --encrypt --in-place --age "$(cat secrets/age.pub)" secrets/global.yaml
  ```

- **Modify the existing encrypted file**
  ```bash
  SOPS_AGE_KEY="$(op read "op://Infrastructure/SOPS Age Key/private key")" sops secrets/global.yaml
  ```

Running `sops secrets/global.yaml` opens your editor on the decrypted content and re-encrypts automatically when you save.
