# External Monitor Brightness

Current setup exposes the Dell external monitor as a Linux backlight device:

```text
/sys/class/backlight/ddcci13
brightnessctl -d ddcci13 -m
```

HyprPanel and the brightness keys use the real `brightnessctl`; there is no
`ddcutil` wrapper. HyprPanel also watches the active backlight brightness file,
so the widget updates quickly after external brightness changes.

## NixOS Pieces

Configured in `nix/hosts/nixos/configuration.nix`:

- `boot.extraModulePackages = [ ddcci-driver ]`
- `boot.kernelModules = [ "i2c-dev" "ddcci" "ddcci-backlight" ]`
- udev starts `ddcci-backlight@%k.service` when an AMDGPU AUX I2C bus appears
- the service writes `ddcci 0x37` to that bus `new_device`

## Machine-Specific Parts

This is currently matched to this machine's AMD GPU I2C adapter names:

```text
AMDGPU DM aux hw bus *
```

The currently working monitor is on:

```text
card1-DP-3 -> i2c-13 -> ddcci13
```

## If Hardware Changes

Check the new adapter names:

```bash
for f in /sys/bus/i2c/devices/i2c-*/name; do echo "$f: $(cat "$f")"; done
```

If the GPU exposes different names, update the udev `ATTR{name}` match in
`nix/hosts/nixos/configuration.nix`.

If the backlight device name changes, HyprPanel should auto-detect it from
`brightnessctl -m`; only scripts that hardcode `ddcci13` need updating.
