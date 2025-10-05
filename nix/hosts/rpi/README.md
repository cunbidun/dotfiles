# NixOS on Raspberry Pi 5

> **⚠️ WARNING: This configuration is currently not working and needs updates.**
> 
> The instructions below are incomplete and may contain errors. Use at your own risk.

## Overview

This directory contains NixOS configuration for Raspberry Pi 5 using the [`nixos-raspberrypi`](https://github.com/nvmd/nixos-raspberrypi) flake. The system can be deployed using `nixos-anywhere` for remote installation.

## Prerequisites

- Raspberry Pi 5 hardware
- USB stick with a bootable Linux distribution (with SSH access)
- SD card for final NixOS installation
- Network access from both the Pi and your build machine

## Installation Steps

### 1. Prepare Boot Environment

1. **Burn a bootable Linux image** (with SSH enabled) to a USB stick
2. **Remove the SD card** from the Raspberry Pi 5 temporarily  
3. **Boot the Pi from the USB stick**

### 2. Install Nix on the Pi

Connect to the Pi via SSH and install Nix:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon --yes
```

### 3. Configure Nix

Add the following lines to `/etc/nix/nix.conf`:

```conf
experimental-features = nix-command flakes
trusted-users = root 
extra-substituters = https://nixos-raspberrypi.cachix.org
extra-trusted-public-keys = nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=
```

Restart the Nix daemon and configure environment:

```bash
systemctl restart nix-daemon  

echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /etc/bash.bashrc
echo 'source /root/.nix-profile/etc/profile.d/nix.sh' >> /etc/bash.bashrc
echo 'PATH="/root/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/environment
```

### 4. Install NixOS Tools

```bash
nix-env -iA nixpkgs.nixos-install-tools
```

### 5. Deploy NixOS

1. **Insert the SD card** into the Raspberry Pi
2. **From your build machine**, run the deployment commands:

```bash
# Phase 1: Disk partitioning
nix run github:nix-community/nixos-anywhere -- --flake .#rpi5 --build-on remote --phases disko root@192.168.1.165

# Phase 2: System installation  
nix run github:nix-community/nixos-anywhere -- --flake .#rpi5 --build-on remote --phases install root@192.168.1.165
```

**Note:** Replace `192.168.1.165` with your Pi's actual IP address.

## Configuration Details

- **Flake target**: `.#rpi5` (defined in `flake.nix`)
- **Architecture**: `aarch64-linux` 
- **Base modules**: Raspberry Pi 5 with 16K page size, VC4 display, and Bluetooth
- **Disk configuration**: Managed by Disko (see `disko.nix`)

## Troubleshooting

- Ensure the Pi is accessible via SSH before deployment
- Check network connectivity between build machine and Pi
- Verify the correct IP address is used in deployment commands
- Monitor the Pi's console output during installation