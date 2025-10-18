# Copilot Instructions

## Project Overview
This is a comprehensive Nix-based dotfiles repository managing configurations across NixOS, macOS (nix-darwin), and Raspberry Pi systems. It uses Nix flakes with Home Manager for declarative configuration management and supports multi-host, multi-architecture deployments.

## Architecture & Key Components

### Core Structure
- **`flake.nix`**: Central entry point defining inputs, outputs, and system configurations
- **`userdata.nix`**: User-specific data (username, email, SSH keys, preferences)
- **`nix/hosts/`**: Host-specific configurations (nixos, macbook, rpi)
- **`nix/home-manager/`**: User environment configurations managed by Home Manager
- **`nix/overlays/`**: Custom package overlays and modifications
- **`utilities/`**: Raw configuration files (used when `hermeticNvimConfig = false`)

### Multi-System Support
The flake defines three system types:
- **NixOS** (`x86_64-linux`): Full system configuration with Hyprland WM
- **macOS** (`aarch64-darwin`): Using nix-darwin for system management
- **Raspberry Pi** (`aarch64-linux`): Specialized config with cross-compilation support

### Configuration Patterns

#### Host Configuration Pattern
Each host has:
- `configuration.nix`: System-level configuration
- `home.nix`: Home Manager imports and user packages
- `disko.nix`: Disk partitioning (NixOS hosts only)

#### Home Manager Module Pattern
User configurations are modular:
```nix
imports = [
  "./nix/home-manager/configs/nvim.nix"
  "./nix/home-manager/configs/hyprland/hyprland.nix"
  # ... other config modules
];
```

## Development Workflows

### System Updates
Use `./scripts/switch.sh` (not `nixos-rebuild` directly):
- Auto-commits changes before building
- Detects OS type and uses appropriate rebuild command
- Validates repository location (`~/dotfiles`)
- Supports custom profiles via argument

#### Testing Configuration Changes
**ALWAYS test configuration changes before switching**:
- **Test build**: `./scripts/switch.sh --test nixos` - Builds configuration without switching to verify it works
- **Switch**: `./scripts/switch.sh nixos` - Actually switches to the new configuration

The `--test` flag performs a full build (including downloading packages and compilation) but skips activation. This ensures the configuration is valid before committing to the switch. Use this workflow:
1. Make configuration changes
2. Run `./scripts/switch.sh --test nixos` to verify build succeeds
3. If test passes, run `./scripts/switch.sh nixos` to activate

Never skip the test step for significant configuration changes as the switch script auto-commits changes.

### Theme Management
The repository implements a sophisticated theming system:
- **`themectl`**: External theme manager (from custom flake input)
- **`darkman`**: Automatic light/dark switching based on location/time
- **Stylix**: System-wide theme application
- **Specializations**: Home Manager creates theme-specific configurations as `{theme}-{polarity}` (e.g., `catppuccin-dark`)

Theme switching workflow:
1. `darkman` detects time/location → triggers theme script
2. `theme-switch.sh` activates appropriate specialization
3. Neovim auto-detects theme changes via `themectl.lua` polling

### Neovim Configuration Modes
The `hermeticNvimConfig` flag in `userdata.nix` controls:
- `true`: Neovim config managed by Nix (requires rebuild to change)
- `false`: Direct editing in `~/.config/nvim` (uses `utilities/nvim/` as source)

## Key Conventions

### File Organization
- Host-specific: `nix/hosts/{hostname}/`
- Shared configs: `nix/home-manager/configs/`
- Raw configs: `utilities/{program}/`
- Scripts: `scripts/` (all executable, OS-aware)

### Flake Input Management
External dependencies are pinned as flake inputs:
- Hyprland ecosystem: `hyprland`, `pyprland`, `xremap-flake`
- Themes: `stylix`, `theme-manager`
- Custom software: `vicinae`, neovim plugins as direct GitHub refs

### Package Management
Packages are organized in `nix/home-manager/packages.nix`:
- `default_packages`: Cross-platform packages
- `linux_packages`: Linux-specific packages
- `darwin_packages`: macOS-specific packages

### Cross-Compilation & Remote Building
The main system can build for Raspberry Pi via:
- `buildMachines` configuration for remote builds
- `emulatedSystems` for local cross-compilation
- Specialized caches: `nixos-raspberrypi.cachix.org`

## Common Patterns

### Adding New Configurations
1. Create module in `nix/home-manager/configs/`
2. Import in appropriate `home.nix`
3. Test with `./scripts/switch.sh`

### Managing Secrets
- SSH keys in `userdata.nix` → `authorizedKeys`
- No other secret management system currently implemented

### Custom Overlays
Add to `nix/overlays/default.nix`:
- Use `mkSubPkgsOverlay.nix` for nixpkgs variants
- Direct overlay files for custom modifications

When modifying this codebase, always consider multi-platform compatibility and use the established patterns for host-specific vs. shared configurations.