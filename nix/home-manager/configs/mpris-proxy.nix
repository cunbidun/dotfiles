# Forward Bluetooth AVRCP media controls (e.g. AirPods stem press) to MPRIS
# players. Runs `mpris-proxy` as a user service bound to bluetooth.target, so it
# starts automatically whenever Bluetooth comes up.
{...}: {
  services.mpris-proxy.enable = true;
}
