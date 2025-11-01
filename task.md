# Task: Integrate `sops-nix` Secrets Backed by 1Password

## Background
- The flake currently has no first-class secret management; there is no `sops` or `agenix` reference in `./flake.nix`, `nix/hosts/*`, or Home Manager configs.
- The repo already provisions 1Password on NixOS (`nix/hosts/nixos/configuration.nix`), but the CLI (`op`) is not yet installed or used.
- Goal: keep secrets encrypted in Git with `sops`, decrypt them at activation using an Age key whose private half lives in 1Password, and let Git operations use 1Password-managed SSH keys.

## Goals
- Add `sops-nix` as a flake input and wire it into NixOS and Home Manager configurations.
- Define a reproducible layout (`secrets/`) for encrypted files plus shared defaults.
- Fetch the Age private key from 1Password via CLI during activation so both system and user secrets can decrypt.
- Ensure `op` CLI and the 1Password SSH agent are available so Git fetch/push works with keys stored in 1Password.
- Replace inline literals such as `environment.etc."geolocation".text` with decrypted `sops` files so sensitive data stays encrypted in Git.
- Document bootstrap steps (Age key creation, storing in 1Password, encrypting first secret, verification).

## Non-goals / Constraints
- Do not automate unattended 1Password unlock; assume the user unlocks the desktop app/CLI before activation scripts run.
- Do not migrate existing machine secrets (none detected); focus on the new framework.
- Raspberry Pi host support is optional; only cover `nixos` unless trivial to extend.

## Prerequisites & Manual Setup
1. Install and sign in to 1Password Desktop; enable “Integrate with 1Password CLI”.
2. Install 1Password CLI v2 (`op`). (Will be handled in config, but manual install is needed before the first `home-manager switch`.)
3. Generate a fresh Age key locally:
   ```bash
   age-keygen -o /tmp/sops-age.key
   ```
   - Copy the public key (`age1...`) into a new repo file `secrets/age.pub`.
   - Store the private key material in a new 1Password item, e.g. `op://Infrastructure/SOPS Age Key/private key`.
   - Delete the temporary local private key file afterwards.
4. Optional: Add SSH keys to 1Password and enable the 1Password SSH agent (Desktop → Settings → Developer → Enable SSH agent).

## Implementation Outline

### 1. Flake wiring
- Add a new input in `flake.nix`:
  ```nix
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
  ```
- Expose it in `outputs` by keeping `inputs` available (already done) and reference modules in host configs.
- Run `nix flake update` after the code changes so `flake.lock` captures the new input.

### 2. Adopt `opnix` for 1Password integration
- Add the `opnix` flake input:
  ```nix
  opnix = {
    url = "github:brizzbuzz/opnix";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
  ```
- Import `opnix.nixosModules.default` alongside `sops-nix` in `nix/hosts/nixos/configuration.nix`. Enable `services.onepassword-secrets` with:
  - `enable = true` and `users = [userdata.username]` so the machine user can read the service token.
  - A `secrets.sopsAgeKey` entry pointing at `op://Infrastructure/SOPS Age Key/private key`, with `path = "/var/lib/sops-nix/keys.txt"`, owner/group `root`, mode `0600`.
  - (Optional) override `tokenFile` if you don’t want to use the default `/etc/opnix-token`.
- Set `sops.age.keyFile = config.services.onepassword-secrets.secretPaths.sopsAgeKey;` so SOPS reads the key file that Opnix materialises.
- Import `opnix.homeManagerModules.default` in `nix/hosts/nixos/home.nix` to allow future user-level secrets (no initial configuration required).
- Keep `_1password-cli` and the Opnix CLI (`inputs.opnix.packages.${pkgs.system}.default`) in system packages so the helper commands are always available.

### 3. Import the module (Linux first)
- NixOS system (`nix/hosts/nixos/configuration.nix`):
  - Add `inputs.sops-nix.nixosModules.sops` and `inputs.opnix.nixosModules.default` to the `imports` list.
  - Set `sops.defaultSopsFile = ../../../../secrets/global.yaml;` (or another agreed filename).
  - Define `sops.secrets.geolocation` with `path = "/etc/geolocation"` and update `environment.etc."geolocation".source = config.sops.secrets.geolocation.path;` so the plaintext payload is removed from the Nix expression.
  - Enable `sops.age.keyFile` reuse via the shared module if using the user’s key file path.
  - Add `_1password-cli` to `environment.systemPackages` if not already included.
- NixOS Home Manager (`nix/hosts/nixos/home.nix`):
  - Add `inputs.sops-nix.homeManagerModules.sops` and `inputs.opnix.homeManagerModules.default`.
  - Allow `opnix` to manage the Age key and SSH agent for this user; no additional Home Manager secrets are needed initially.

### 4. Secrets directory structure
- Create a git-tracked directory `secrets/` with:
  - `README.md` describing how to edit (`sops secrets/global.yaml`), the expected 1Password item name, and the public key file.
  - `.gitattributes` to ensure Git treats these files as binary and avoid merge conflicts (`*.yaml diff=`.
  - `age.pub` containing the Age public key(s) used for encryption.
  - Seed files:
    - `global.yaml` (system-wide secrets, e.g., `geolocation`).
    - `global.template.yaml` (plaintext example to copy/edit before encrypting).
  - Each YAML file should include the SOPS metadata block referencing the Age public key.
  - Prepopulate `global.yaml` with a `geolocation` entry matching the current coordinates so it can be decrypted immediately after bootstrap.
- Update `.gitignore` if necessary to ignore decrypted artefacts (e.g., `secrets/*.dec`, `*.backup`).

### 5. 1Password CLI & SSH agent configuration
- Ensure `_1password-cli` remains installed in the Linux profiles; `opnix` expects it at activation time.
- Document the need for a 1Password service account token stored at `/etc/opnix-token` (or the configured path). Add the user to the generated `onepassword-secrets` group if they should read the token.
- Document that the user must unlock/sign in via the 1Password desktop app/CLI so `opnix` can retrieve the Age key.

### 6. Example secret usage
- Replace `environment.etc."geolocation".text` with the decrypted file at `config.sops.secrets.geolocation.path` (already covered above).
- Document in `secrets/README.md` how to add more entries later (e.g., API keys) so future expansion stays consistent.

## Testing / Verification Checklist
1. With 1Password unlocked and `/etc/opnix-token` populated, run `sudo systemctl start opnix-secrets.service` to materialise the Age key at `/var/lib/sops-nix/keys.txt`. If the unit is not yet available, seed the file manually with `op read "op://Infrastructure/SOPS Age Key/private key" | sudo tee /var/lib/sops-nix/keys.txt >/dev/null && sudo chmod 600 /var/lib/sops-nix/keys.txt` and rerun the switch.
2. Run `home-manager switch --flake .#nixos` → no-op, but confirms imports don’t break activation.
3. Run `nixos-rebuild switch --flake .#nixos` → ensure the system unit decrypts without prompting.
4. Lock 1Password and rerun `sudo systemctl start opnix-secrets.service` to confirm it handles the locked state gracefully (should warn but keep previous key).
5. Update `secrets/global.yaml` with a new `geolocation` value, run `nixos-rebuild switch`, and confirm `/etc/geolocation` reflects the change.
6. Confirm Git SSH:
   - `ssh -T git@github.com` should prompt via 1Password agent and succeed.
   - `GIT_SSH_COMMAND="ssh -v" git ls-remote` to verify the socket is used.

## Deliverables
- Updated `flake.nix` and `flake.lock`.
- `opnix` input added and integrated into system & Home Manager module lists.
- Updated host config to enable `services.onepassword-secrets` with a `sopsAgeKey` secret feeding `/var/lib/sops-nix/keys.txt`, and Home Manager to import the module for future use.
- `environment.etc."geolocation"` updated to source from `sops.secrets.geolocation.path`.
- New `secrets/` directory with documentation and placeholder encrypted files.
- Updated documentation (existing `README.md` or new `docs/secrets.md`) outlining bootstrap steps.

## Risks & Open Questions
- Running `op` inside system activation relies on an unlocked session; this spec opts for “warn and continue” to avoid breaking `switch`. Consider adding a `home.sessionVariables` entry reminding the user to run `op signin --account ...` when needed.
- If future hosts run headless (no desktop), additional automation (service account, scdaemon) may be required; out of scope for now.
