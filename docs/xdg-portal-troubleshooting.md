# XDG Portal File Chooser Troubleshooting

1. Symptom: `xdg-open` works, but Chrome upload does not open `yazi`.
2. Cause we hit: `xdg-desktop-portal` selected `gtk` as `FileChooser` fallback.
3. Why fallback happened: `termfilechooser` backend was not visible to portal at startup.
4. Check backend registration:
   `ls /run/current-system/sw/share/xdg-desktop-portal/portals | rg termfilechooser`
5. Check portal choice logs:
   `journalctl --user -u xdg-desktop-portal.service --no-pager | rg "Choosing .*FileChooser"`
6. Check runtime backend activity while testing upload:
   `journalctl --user -f -u xdg-desktop-portal-termfilechooser.service -u xdg-desktop-portal-gtk.service`
7. If missing backend, ensure it is system-visible:
   add `pkgs.xdg-desktop-portal-termfilechooser` to `environment.systemPackages`, then switch.
8. Restart portals after changes:
   `systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-termfilechooser.service xdg-desktop-portal-gtk.service`
9. Confirm manual portal call:
   `gdbus call --session --dest org.freedesktop.portal.Desktop \`
   `--object-path /org/freedesktop/portal/desktop \`
   `--method org.freedesktop.portal.FileChooser.OpenFile "" "test" "{}"`
