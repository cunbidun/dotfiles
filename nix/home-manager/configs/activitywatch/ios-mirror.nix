# Makes the iPhone visible in the Activity dashboard, by copying the Screen Time
# importer's buckets into the two the web UI actually reads. The why is in
# ./ios-mirror.py; this file is only about where the job runs.
#
# It belongs on the server rather than next to the importer on the MacBook. The
# importer is pinned to that Mac because Full Disk Access and ~/Library/Biome are
# machine-local (see ./darwin.nix); this reads and writes buckets over HTTP and
# touches nothing else, so it is a property of the datastore, and putting it here
# means it also keeps nothing working that depends on a laptop being awake.
#
# Being server-local is what lets it talk to 127.0.0.1: aw-server-rust always
# admits a loopback Origin, so unlike every remote client this needs no entry in
# ./server.nix's cors list.
{pkgs, ...}: let
  endpoint = import ./endpoint.nix;
in {
  systemd.user.services.activitywatch-ios-mirror = {
    Unit = {
      Description = "Mirror imported iOS Screen Time buckets into watcher-shaped ones";
      After = ["network.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${./ios-mirror.py} --server http://127.0.0.1:${toString endpoint.port}";
    };
  };

  systemd.user.timers.activitywatch-ios-mirror = {
    Unit.Description = "Periodic iOS Screen Time bucket mirror";
    Timer = {
      # Ten minutes is as fast as this is worth running: the source is iCloud's
      # Screen Time sync, which lands events in batches tens of minutes after the
      # fact, so a tighter loop would only re-scan the same window.
      OnBootSec = "2m";
      OnUnitActiveSec = "10m";
      # Catch up after a reboot rather than waiting out the interval, so a restart
      # near the top of the loop does not leave a visible hole in the day.
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
