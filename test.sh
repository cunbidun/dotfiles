#!/usr/bin/env bash
set -euo pipefail

# Let GTK use dconf (hot-reload capable) and force a light variant so the portal
# spawned file chooser matches the foreground colors you set in css overrides.
unset GSETTINGS_BACKEND
export GSETTINGS_SCHEMA_DIR="/nix/store/6546hslddlnvg5fmx8vv3man2blcprib-gsettings-desktop-schemas-49.1/share/gsettings-schemas/gsettings-desktop-schemas-49.1/glib-2.0/schemas:/nix/store/cs86fhm7hsgxm20m826cl5qqc4nyg33s-gtk+3-3.24.51/share/gsettings-schemas/gtk+3-3.24.51/glib-2.0/schemas"

# Push GTK_THEME into the user systemd environment before restarting the portals,
# so the portal processes actually inherit the light variant.
systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gtk.service
dbus-update-activation-environment --systemd GTK_THEME

# Flip to a different theme and back to trigger a settings-changed signal.
gsettings set org.gnome.desktop.interface gtk-theme Adwaita
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
gsettings set org.gnome.desktop.interface color-scheme prefer-light
