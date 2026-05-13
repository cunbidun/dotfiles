# Secrets Workflow

This directory holds the encrypted payloads that `sops-nix` decrypts during system or Home Manager activation.
The files checked into Git **must remain encrypted**; bootstrap with the steps below before running any
`nixos-rebuild` or `home-manager switch`.

`sops-nix` uses an Age key stored at `/var/lib/sops-nix/keys.txt`. You place it there once manually after a
fresh install by reading it from your 1Password `Private` vault.

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

2. **Place the Age key** using your interactive 1Password session:

   ```bash
   op read "op://Private/SOPS Age Key/private key" | sudo tee /var/lib/sops-nix/keys.txt
   sudo chmod 600 /var/lib/sops-nix/keys.txt
   ```

3. **Reapply** so `sops-nix` can decrypt using the key:

   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

## Bootstrapping a remote host

Remote hosts such as `home-server` also need the same Age private key at
`/var/lib/sops-nix/keys.txt` before `sops-nix` can decrypt secrets during activation.

1. **Apply the configuration once**. The build and copy can succeed, but activation may fail with:

   ```text
   sops-install-secrets: cannot read keyfile '/var/lib/sops-nix/keys.txt'
   ```

2. **Copy the existing local Age key to the remote host**:

   ```bash
   sudo cat /var/lib/sops-nix/keys.txt | ssh root@home-server \
     'install -d -m 700 /var/lib/sops-nix && umask 077 && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'
   ```

   If the local key is not available yet, read it from 1Password first:

   ```bash
   op read "op://Private/SOPS Age Key/private key" | ssh root@home-server \
     'install -d -m 700 /var/lib/sops-nix && umask 077 && cat > /var/lib/sops-nix/keys.txt && chmod 600 /var/lib/sops-nix/keys.txt'
   ```

3. **Reapply the remote configuration**:

   ```bash
   nix run .#switch -- home-server
   ```

4. **Verify secrets and generated config without printing secret contents**:

   ```bash
   ssh root@home-server 'test -s /var/lib/sops-nix/keys.txt'
   ssh root@home-server 'test -s /home/cunbidun/.config/opencode/github_read_only_token'
   ssh root@home-server 'su - cunbidun -c "opencode debug config | jq -r \".lsp | keys | join(\\\",\\\")\""'
   ```

The OpenCode GitHub token is stored encrypted in `secrets/global.yaml` and written by `sops-nix` to
`/home/cunbidun/.config/opencode/github_read_only_token`. 1Password only needs to keep the `SOPS Age Key`
bootstrap item; the GitHub token does not need to be duplicated there.

## Encrypting the secret files

Create or update the file with `sops`:

- **Create a new encrypted file**

  ```bash
  sops --encrypt --in-place --age "$(cat secrets/age.pub)" secrets/global.yaml
  ```

- **Modify the existing encrypted file**

  ```bash
  SOPS_AGE_KEY="$(op read "op://Private/SOPS Age Key/private key")" sops secrets/global.yaml
  ```

Running `sops secrets/global.yaml` opens your editor on the decrypted content and re-encrypts automatically
when you save.
