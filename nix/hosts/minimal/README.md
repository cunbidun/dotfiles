# Minimal NixOS USB Installer

A bootable USB installer with SSH enabled for remote installation using
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

## Build the ISO

```bash
nix build .#nixosConfigurations.minimal.config.system.build.isoImage
```

The ISO will be in `result/iso/`.

## Burn to USB

```bash
# Find your USB device (e.g., /dev/sdb)
lsblk

# Burn the ISO (replace /dev/sdX with your USB device)
# Using bs=32M for faster writes on modern USB 3.0+ drives
sudo dd if=result/iso/nixos-minimal-*.iso of=/dev/sdX bs=32M \
  status=progress oflag=sync
```

## Usage

1. **Boot from USB** on target machine
2. **Find IP address**: The system will get an IP via DHCP. Check your
   router or use `nmap`:

   ```bash
   sudo nmap -sn  192.168.1.0/24
   ```

3. **SSH into the installer** (your SSH key is already authorized):

   ```bash
   ssh root@<ip-address>
   ```

4. **Run nixos-anywhere** from your machine to install NixOS:

   ```bash
   nix run github:nix-community/nixos-anywhere \
     --flake .#<profile name> --phases disko root@<ip-address>

   nix run github:nix-community/nixos-anywhere \
     --flake .#<profile name> --phases install root@<ip-address>
   ```

## What's included

- SSH server with your public key for root access
- NetworkManager for easy network configuration
- Essential tools: vim, git, wget, curl, htop, tmux, rsync, parted, etc.
- EFI and legacy BIOS boot support

## Troubleshooting

### No network connection

If DHCP doesn't work automatically, SSH from another machine on the
same network or:

- Use `nmcli` or `nmtui` to configure network manually after booting

### Can't find IP address

- Check DHCP leases on your router
- Connect a monitor/keyboard temporarily and run `ip addr`
- Use the target machine's MAC address to set a static DHCP reservation
