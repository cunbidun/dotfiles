# Secrets Workflow

This directory holds the encrypted payloads that `sops-nix` decrypts during system or Home Manager activation.
The files checked into Git **must remain encrypted**; bootstrap with the steps below before running any
`nixos-rebuild` or `home-manager switch`.

System secrets and user secrets are decrypted by separate `sops-nix` activations:

- `systemctl status sops-nix.service` decrypts `system.yaml` with `/var/lib/sops-nix/keys.txt`.
- `systemctl --user status sops-nix.service` decrypts `user.yaml` with
  `$HOME/.config/sops/age/keys.txt`.

Both files contain the same Age private key from your 1Password `Private` vault, but permissions stay scoped
to the service that reads them.

## 1Password + Age bootstrap

1. Ensure the 1Password desktop app is installed and unlocked. In Settings ➝ Developer, enable
   **Integrate with 1Password CLI**.
2. Install the CLI (`op`). On NixOS/Home Manager this happens automatically once the new configuration is
   applied, but you need it available locally for the initial setup (e.g. `nix shell nixpkgs#_1password-cli`).
3. Generate an Age key pair and capture the public half:

   ```bash
   nix shell nixpkgs#age -c age-keygen -o /tmp/sops-age.key
   cat /tmp/sops-age.key | grep "^# public key:" | cut -d' ' -f4 > age.pub
   ```

   Store the private key in 1Password (`Private` vault → `SOPS Age Key` item → `private key` field),
   then delete `/tmp/sops-age.key`.
4. Update `age.pub` in this directory with your generated public key (replace the placeholder value in the repo).
5. Create a 1Password item in the `Private` vault:
   - Item title: **SOPS Age Key**
   - Add a field labelled exactly **private key** containing the `AGE-SECRET-KEY-…` line.

   Verify: `op read "op://Private/SOPS Age Key/private key"` should print the key.

## First-time switch (fresh install)

1. **Apply the configuration** (secrets will fail to decrypt on first run, that's okay):

   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

2. **Place the Age key** for system and user activation using your interactive 1Password session:

   ```bash
   op read "op://Private/SOPS Age Key/private key" | sudo tee /var/lib/sops-nix/keys.txt
   sudo chmod 600 /var/lib/sops-nix/keys.txt

   install -d -m 700 ~/.config/sops/age
   op read "op://Private/SOPS Age Key/private key" > ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

3. **Reapply** so both `sops-nix` services can decrypt using their keys:

   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

## Bootstrapping a remote host

Remote hosts such as `home-server` need the same Age private key at both service-specific paths before both
`sops-nix` activations can decrypt secrets.

1. **Apply the configuration once**. The build and copy can succeed, but activation may fail with:

   ```text
   sops-install-secrets: cannot read keyfile '/var/lib/sops-nix/keys.txt'
   ```

2. **Copy the existing local Age key to the remote host**:

   ```bash
   sudo cat /var/lib/sops-nix/keys.txt | ssh root@home-server \
     'install -d -m 700 /var/lib/sops-nix && umask 077 && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'

   sudo cat /var/lib/sops-nix/keys.txt | ssh home-server \
     'install -d -m 700 ~/.config/sops/age && umask 077 && cat > ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt'
   ```

   If the local key is not available yet, read it from 1Password first:

   ```bash
   op read "op://Private/SOPS Age Key/private key" | ssh root@home-server \
     'install -d -m 700 /var/lib/sops-nix && umask 077 && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'

   op read "op://Private/SOPS Age Key/private key" | ssh home-server \
     'install -d -m 700 ~/.config/sops/age && umask 077 && cat > ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt'
   ```

3. **Reapply the remote configuration**:

   ```bash
   nix run .#switch -- home-server
   ```

4. **Verify secrets and generated config without printing secret contents**:

   ```bash
   ssh root@home-server 'test -s /var/lib/sops-nix/keys.txt'
   ssh home-server 'test -s ~/.config/sops/age/keys.txt'
   ssh root@home-server 'test -s /home/cunbidun/.config/opencode/github_read_only_token'
   ssh root@home-server 'su - cunbidun -c "opencode debug config | jq -r \".lsp | keys | join(\\\",\\\")\""'
   ```

The OpenCode GitHub token, ninerouter key, and HyprPanel weather key are stored encrypted in
`secrets/user.yaml` and written by user `sops-nix` under `$HOME/.config`. The geolocation secret and
system-service credentials are stored encrypted in `secrets/system.yaml`. 1Password only needs to keep the
`SOPS Age Key` bootstrap item; service tokens do not need to be duplicated there.

## Encrypting the secret files

Create or update the file with `sops`:

- **Create a new encrypted file**

  ```bash
  sops --encrypt --in-place --age "$(cat secrets/age.pub)" secrets/user.yaml
  ```

- **Modify the existing encrypted file**

  ```bash
  SOPS_AGE_KEY="$(op read "op://Private/SOPS Age Key/private key")" sops secrets/user.yaml
  ```

Running `sops secrets/user.yaml` or `sops secrets/system.yaml` opens your editor on the decrypted content and
re-encrypts automatically when you save.
