# External Monitor Brightness

Current setup exposes the Dell external monitor as a Linux backlight device:

```text
/sys/class/backlight/ddcci13
brightnessctl -d ddcci13 -m
```

QuickShell and the brightness keys use the real `brightnessctl`; there is no
`ddcutil` wrapper. QuickShell also reads the active backlight brightness value,
so the widget updates quickly after external brightness changes.

## NixOS Pieces

Configured in `nix/hosts/nixos/configuration.nix`:

- `boot.extraModulePackages = [ ddcci-driver ]`
- `boot.kernelModules = [ "i2c-dev" "ddcci" "ddcci-backlight" ]`
- `ddcci-backlight.timer` runs once per second while boot settles
- `ddcci-backlight.service` stops the timer once `/sys/class/backlight/ddcci*` exists
- when missing, the service binds `ddcci 0x37` on AMDGPU AUX I2C buses

## Machine-Specific Parts

The service script matches this machine's AMD GPU I2C adapter names:

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

If names differ, update the `grep` adapter match in `configuration.nix`.

If the backlight device name changes, QuickShell should auto-detect it from
`brightnessctl -m`; only scripts that hardcode `ddcci13` need updating.
