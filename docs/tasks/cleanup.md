# Implementation Plan: Nix Configuration Cleanup

**Last updated:** 2026-06-05

## Scope
- In scope: structural cleanup for the Nix flake, NixOS host modules, Home Manager modules, shared service modules, flake app naming, standalone Home Manager switching, and static-check hygiene.
- In scope: reducing duplicated host and user configuration while preserving current behavior.
- In scope: detaching personal Home Manager activation from `nixos-rebuild switch` / `darwin-rebuild switch` so system switches can support multiple users without owning a specific user's home.
- In scope: documenting package/config ownership boundaries between system profiles and Home Manager profiles.
- Out of scope: refreshing flake inputs, changing pinned package versions, changing desktop behavior, redesigning Hyprpanel, or rebuilding/redeploying systems without a separate explicit request.

## Goals / Success Criteria
- `nix flake show --all-systems --no-write-lock-file` continues to evaluate successfully.
- Existing hosts keep the same intended behavior: `nixos`, `home-server`, `test-vm`, `minimal`, and `macbook-m1`.
- Repeated Home Manager and NixOS boilerplate is moved into focused shared modules or profiles.
- NixOS/Darwin system switches no longer activate the primary user's Home Manager profile by default.
- Personal Home Manager profiles are exposed through `homeConfigurations` and can be switched independently with `home-manager switch --flake`.
- System configuration still creates required OS users and shared system services, but user-specific dotfiles, packages, editor config, desktop config, and shell config live under standalone Home Manager outputs.
- System-vs-home package ownership is explicit enough that duplicated apps are intentional, not accidental.
- Flake app names match repository docs and script help text.
- `deadnix` and `statix` output is reduced to intentional exceptions.
- Cleanup is split into small, reviewable patches with validation after each patch.

## Current State (Audit)
- [flake.nix](../../flake.nix) exposes `apps.*.flake-input`, while [AGENTS.md](../../AGENTS.md) and [scripts/flake_input_versions.py](../../scripts/flake_input_versions.py) refer to `nix run .#flake-input-versions`.
- [flake.nix](../../flake.nix) defines many direct inputs. Several direct inputs do not use `inputs.nixpkgs.follows`, contributing to many transitive nixpkgs nodes in `flake.lock`.
- [flake.nix](../../flake.nix) imports Home Manager modules directly inside `nixosConfigurations` and `darwinConfigurations` through `home-manager.nixosModules.home-manager`, `home-manager.darwinModules.home-manager`, and `mkHomeManagerModule`. This couples personal home activation to system switches.
- [nix/hosts/shared/common.nix](../../nix/hosts/shared/common.nix) mixes locale, users, sudo, SSH, Tailscale, Docker, nix-ld, and zsh enablement in one shared module.
- [nix/hosts/shared/common.nix](../../nix/hosts/shared/common.nix) creates the current user from `userdata.username`; this is system-owned user creation and should remain separate from Home Manager profile ownership when additional users are added.
- [nix/hosts/test-vm/configuration.nix](../../nix/hosts/test-vm/configuration.nix) repeats user, SSH, sudo, locale, and zsh settings already represented in shared modules.
- [nix/hosts/nixos/configuration.nix](../../nix/hosts/nixos/configuration.nix) is large and mixes hardware, secrets, desktop session setup, display manager, PAM, udev rules, DDC/CI service logic, audio, container services, geoclue, Stylix, and packages.
- [nix/hosts/shared/tailscale-base.nix](../../nix/hosts/shared/tailscale-base.nix) and [nix/hosts/home-server/tailscale-services.nix](../../nix/hosts/home-server/tailscale-services.nix) both define Tailscale OAuth secret names and auth-key generation flow.
- Home Manager host files repeat `home.username`, `home.homeDirectory`, `programs.home-manager.enable`, `programs.atuin.enable`, common imports, and package-import boilerplate:
  - [nix/hosts/nixos/home.nix](../../nix/hosts/nixos/home.nix)
  - [nix/hosts/home-server/home.nix](../../nix/hosts/home-server/home.nix)
  - [nix/hosts/test-vm/home.nix](../../nix/hosts/test-vm/home.nix)
  - [nix/hosts/macbook/home.nix](../../nix/hosts/macbook/home.nix)
- Current package ownership is mixed. Some tools live in `environment.systemPackages`, while most personal tools live in `home.packages`. That can be acceptable, but duplicated ownership should be intentional.
- `deadnix --fail .` reports unused lambda arguments across overlays, host modules, hardware modules, Home Manager modules, and [nix/apps/vm.nix](../../nix/apps/vm.nix).
- `statix check .` reports repeated-key style issues in several modules and simple idiom issues such as assignment instead of `inherit`.
- Current tree had an existing modified [nix/apps/vm.nix](../../nix/apps/vm.nix) before this cleanup task was created, so cleanup patches should avoid overwriting unrelated work there unless that change is intentionally included.

## Approach
- Work in small batches and validate after each batch.
- Prefer behavior-preserving moves first: create new shared modules/profiles, import them, then remove duplicated definitions.
- Keep host-specific files as thin composition roots: hostname, state version, host-only imports, and truly host-specific settings.
- Keep feature modules focused around one concern: users, SSH, nix settings, SOPS, desktop session, DDC/CI backlight, Tailscale OAuth, Home Manager base profile, Home Manager desktop profile.
- Detach Home Manager in two phases. First, add standalone `homeConfigurations` while keeping current embedded Home Manager modules as a compatibility path. Second, remove embedded Home Manager from system outputs once standalone switches evaluate and activate cleanly.
- Use names that make the user and host explicit, for example `cunbidun@nixos`, `cunbidun@home-server`, `cunbidun@test-vm`, and `cunbidun@macbook-m1`.
- Treat NixOS/Darwin users as system accounts and Home Manager profiles as personal ownership. Future users should get their own `homeConfigurations` entries without needing to modify the system switch path except for account creation and group membership.
- Use Nix module composition instead of copy/paste host variants. Where behavior needs host-specific differences, use focused modules, ordinary imports, and `lib.mkDefault`/`lib.mkForce` only where priorities are genuinely needed.
- Review flake input `follows` conservatively. Do not force follows for version-pinned application flakes until their lock behavior is checked.

## Ownership Boundaries
- System should own boot, hardware, users, groups, login shells, display/session availability, PAM, polkit, system services, Docker/Podman, SSH daemon, globally required secrets, globally required fonts, and emergency repair tools.
- Home Manager should own dotfiles, personal packages, shell config, Git config, editor config, terminal config, browser/user app config, Hyprland settings, user systemd services, themes, MIME defaults, and personal desktop workflows.
- Some programs intentionally have both layers:
  - `programs.zsh.enable` in NixOS makes zsh a system login shell; `programs.zsh.enable` in Home Manager owns the user's zsh config.
  - `programs.hyprland.enable` and `programs.uwsm.enable` in NixOS provide session integration; Home Manager Hyprland config owns personal window manager settings.
- Avoid installing the same package in both `environment.systemPackages` and `home.packages` unless there is a reason, such as `git`, `vim`, `neovim`, or `sops` being available for system repair before Home Manager activates.
- If system and standalone Home Manager use different nixpkgs inputs, the same app can resolve to different `/nix/store` paths. Standalone Home Manager should use the same `mkPkgs` helper or same primary nixpkgs input as the system outputs unless a difference is intentional.
- If a package exists in both system and home profiles, check command precedence with `which -a <command>` before assuming which version runs.

## Data Model Details (if applicable)
- Tables: not applicable.
- Indexes/constraints: not applicable.
- Backfill/compat: keep `system.stateVersion` and `home.stateVersion` unchanged unless a separate migration explicitly requires changing them.
- Future user modeling should stop treating `userdata.username` as the only important user. Prefer a map/list of system users for account creation and separate `homeConfigurations` entries for each user's personal profile.

## API Contract (if applicable)
- Endpoints: not applicable.
- Auth model: not applicable.
- Error handling: not applicable.

## Frontend UX (if applicable)
- Surfaces: not applicable.
- States: not applicable.

## Operational Notes
- Config/env: preserve existing `userdata.nix`, SOPS secret paths, Tailscale tags, Hyprland package pinning, and Home Manager state versions.
- Config/env: after detaching Home Manager, system switches should be run with `nix run .#switch -- nixos` or `nixos-rebuild switch --flake .#nixos`; user switches should be run separately with `home-manager switch --flake .#cunbidun@nixos`.
- Activation order: when both system and home changed, run the system switch first, then run the Home Manager switch.
- Home Manager CLI availability: once detached, make sure `home-manager` is available through system packages, user packages, or `nix run home-manager -- switch --flake .#...`.
- Secrets boundary: system-created secrets under `/etc` or `/run` can be consumed by Home Manager only if ownership and mode allow it. User-path secrets currently created by NixOS should be reviewed when adding multiple users.
- Logging/metrics: keep current systemd service behavior unless extracting a service into a module requires explicit naming cleanup.
- Rate limits: Tailscale OAuth/API sync code should not be made more aggressive during cleanup.
- Rollout/rollback: each batch should be one commit-sized change. Roll back by reverting the batch commit.
- Validation commands:
  - `nix flake show --all-systems --no-write-lock-file`
  - `nix run nixpkgs#deadnix -- --fail .`
  - `nix run nixpkgs#statix -- check .`
  - `nix run .#flake-input-versions` after the flake app alias is fixed
  - Host-specific build checks when touching host modules, for example `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link`

## Implementation Checklist
- **Backend**
  - [x] Expose `flake-input-versions` in [flake.nix](../../flake.nix), preferably while keeping `flake-input` as a compatibility alias if useful.
  - [x] Run `nix run .#flake-input-versions` and confirm it matches [AGENTS.md](../../AGENTS.md) and [scripts/flake_input_versions.py](../../scripts/flake_input_versions.py).
  - [ ] Add a `mkHomeConfiguration` helper in [flake.nix](../../flake.nix) using `home-manager.lib.homeManagerConfiguration`, `mkPkgs`, and the existing `extraSpecialArgs` values.
  - [ ] Add standalone `homeConfigurations` entries for the existing homes: `cunbidun@nixos`, `cunbidun@home-server`, `cunbidun@test-vm`, and `cunbidun@macbook-m1`.
  - [ ] Validate standalone Home Manager evaluation before removing embedded modules.
  - [ ] Remove `homePath` from `mkNixosHost` after standalone Home Manager is confirmed.
  - [ ] Remove `home-manager.nixosModules.home-manager`, `home-manager.darwinModules.home-manager`, and `mkHomeManagerModule` from system outputs after standalone Home Manager is confirmed.
  - [ ] Keep system-owned user creation and group membership in NixOS/Darwin modules, but move personal dotfiles, packages, and session settings to standalone Home Manager profiles only.
  - [ ] Create focused NixOS shared modules from [nix/hosts/shared/common.nix](../../nix/hosts/shared/common.nix): users, locale, SSH, sudo/security, Docker, nix-ld, and shell enablement.
  - [ ] Update [nix/hosts/nixos/configuration.nix](../../nix/hosts/nixos/configuration.nix), [nix/hosts/home-server/configuration.nix](../../nix/hosts/home-server/configuration.nix), and [nix/hosts/test-vm/configuration.nix](../../nix/hosts/test-vm/configuration.nix) to import the focused shared modules.
  - [ ] Extract DDC/CI backlight configuration from [nix/hosts/nixos/configuration.nix](../../nix/hosts/nixos/configuration.nix) into a host feature module.
  - [ ] Extract desktop session pieces from [nix/hosts/nixos/configuration.nix](../../nix/hosts/nixos/configuration.nix): Hyprland/UWSM, greetd, PAM/keyring, portals if appropriate, geoclue, and Stylix system defaults.
  - [x] Consolidate Tailscale OAuth auth-key generation from [nix/hosts/shared/tailscale-base.nix](../../nix/hosts/shared/tailscale-base.nix) and [nix/hosts/home-server/tailscale-services.nix](../../nix/hosts/home-server/tailscale-services.nix) into one parameterized module.
  - [ ] Review direct flake inputs in [flake.nix](../../flake.nix) for safe `inputs.nixpkgs.follows` additions.
- **Frontend**
  - [ ] Not applicable.
- **Data & Migrations**
  - [ ] Preserve all `system.stateVersion` values.
  - [ ] Preserve all `home.stateVersion` values.
  - [ ] Preserve SOPS secret names, owners, modes, and paths unless a separate secret migration is planned.
  - [ ] Decide how future system users are represented before adding the next user.
- **Docs & DX**
  - [x] Create Home Manager profiles such as `nix/home-manager/profiles/base.nix`, `linux.nix`, `desktop.nix`, `server.nix`, and `darwin.nix` if that layout remains appropriate after the first extraction.
  - [x] Move repeated Home Manager imports and common program enablement into those profiles.
  - [ ] Document the split workflow: system switch separately from Home Manager switch.
  - [ ] Document how to add a second user: add system account/groups in a system module, add a new user data source if needed, and add a separate `homeConfigurations` entry for that user's home profile.
  - [ ] Document package ownership rules for `environment.systemPackages` vs `home.packages`.
  - [x] Update any docs or scripts that mention the old flake app name if the compatibility alias is not kept.
  - [ ] Group repeated top-level attr assignments where it improves readability, especially `home = { ...; }`, `programs = { ...; }`, `networking = { ...; }`, and `isoImage = { ...; }`.
  - [ ] Remove unused lambda arguments reported by `deadnix`, avoiding [nix/apps/vm.nix](../../nix/apps/vm.nix) unless its current modification is intentionally included.
- **Testing**
  - [ ] Run `nix flake show --all-systems --no-write-lock-file` after every batch.
  - [ ] Run `nix run nixpkgs#deadnix -- --fail .` after static cleanup batches.
  - [ ] Run `nix run nixpkgs#statix -- check .` after style cleanup batches.
  - [ ] Run `nix build .#homeConfigurations."cunbidun@nixos".activationPackage --no-link` after adding standalone Home Manager outputs.
  - [ ] Run `nix build .#homeConfigurations."cunbidun@home-server".activationPackage --no-link` after adding standalone Home Manager outputs.
  - [ ] Run `nix build .#homeConfigurations."cunbidun@test-vm".activationPackage --no-link` after adding standalone Home Manager outputs.
  - [ ] Run `nix build .#homeConfigurations."cunbidun@macbook-m1".activationPackage --no-link` after adding standalone Home Manager outputs.
  - [ ] Build `.#nixosConfigurations.nixos.config.system.build.toplevel` after desktop host refactors.
  - [ ] Build `.#nixosConfigurations.home-server.config.system.build.toplevel` after shared or Tailscale refactors.
  - [ ] Build `.#nixosConfigurations.test-vm.config.system.build.toplevel` after VM/shared module refactors.
  - [ ] Build `.#packages.x86_64-linux.minimal-iso` after touching minimal installer config.

## Open Questions

- Should `flake-input` remain as a compatibility alias, or standardize only on `flake-input-versions`?
- Should detached Home Manager outputs use `cunbidun@nixos`, host-only `nixos`, or user-only `cunbidun` with
  separate profiles inside the module?
- Should all Linux Home Manager hosts share one base profile, or keep server and desktop mostly separate with
  only shell/editor/git shared?
- Should the system continue creating `userdata.username` by default, or model system users as a list/map now
  that a second user is expected?
- Should there be a transition period where embedded and standalone HM outputs both exist, or remove embedded
  HM immediately after the standalone builds pass?
- Should Tailscale OAuth/key generation live under `nix/hosts/shared`, or be a small reusable NixOS module
  with explicit options?
- Which direct flake inputs are intentionally allowed to keep their own nixpkgs due to upstream compatibility?
- Should static style cleanup be done separately from structural module extraction to keep diffs reviewable?
