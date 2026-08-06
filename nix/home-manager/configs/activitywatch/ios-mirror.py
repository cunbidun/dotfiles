#!/usr/bin/env python3
"""Mirror aw-import-screentime's iOS buckets into watcher-shaped ones.

aw-webui's Activity view does not look up buckets by type. For a given host it
resolves the literal ids ``aw-watcher-window_<host>`` and ``aw-watcher-afk_<host>``
(aw-webui's canonicalEvents), intersects the two, and renders every panel on the
page from the result. The Screen Time importer writes
``aw-import-screentime_ios_<host>`` of type ``app`` instead, so the dashboard finds
nothing and reports 0s while the events sit in the datastore, fully queryable.

Nothing is wrong with those events -- ``{app, title}`` is already exactly what
aw-watcher-window emits, and the intervals arrive non-overlapping. Only the bucket
id and type are unreachable, so this copies them across under the names the UI
insists on.

The AFK bucket is synthesized rather than measured: on a phone there is no idle
detector, but a foreground app *is* the user being present, so each mirrored
interval yields a matching not-afk span. The intersection in canonicalEvents is
then the identity, and "Time active" becomes the sum of foreground time -- the
only definition of active the source data can support.

Runs periodically and is idempotent, which matters because Screen Time is not a
heartbeat stream: iCloud delivers events in batches tens of minutes late, and the
importer backfills them with their true past timestamps. So each pass rescans a
window rather than appending past a high-water mark, and drops anything already
mirrored. Events that arrive backdated further than --lookback are missed; a
freshly created target bucket is backfilled in full instead.
"""

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

SOURCE_PREFIX = "aw-import-screentime_ios_"

# Both roles this script writes as. The ids matter (the UI matches on them); the
# client names are cosmetic, but say where the events came from rather than
# impersonating the real watchers, which do not run on a phone.
WINDOW_CLIENT = "aw-import-screentime-mirror"
WINDOW_TYPE = "currentwindow"
AFK_TYPE = "afkstatus"


class Server:
    def __init__(self, base, timeout=30):
        self.base = base.rstrip("/")
        self.timeout = timeout

    def _call(self, method, path, body=None, params=None):
        url = f"{self.base}/api/0/{path}"
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = None
        headers = {}
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=self.timeout) as resp:
            raw = resp.read()
        return json.loads(raw) if raw else None

    def buckets(self):
        return self._call("GET", "buckets/")

    def create_bucket(self, bucket_id, btype, hostname):
        """Returns True if this call is what created the bucket.

        aw-server-rust answers an existing bucket with 304, which urllib raises
        rather than returns -- that is the whole signal, so it is caught here
        instead of being allowed to look like a failure.
        """
        try:
            self._call(
                "POST",
                f"buckets/{urllib.parse.quote(bucket_id)}",
                body={"client": WINDOW_CLIENT, "type": btype, "hostname": hostname},
            )
            return True
        except urllib.error.HTTPError as err:
            if err.code == 304:
                return False
            raise

    def events(self, bucket_id, start, end):
        return self._call(
            "GET",
            f"buckets/{urllib.parse.quote(bucket_id)}/events",
            params={"start": start.isoformat(), "end": end.isoformat(), "limit": -1},
        )

    def insert(self, bucket_id, events):
        if not events:
            return
        self._call("POST", f"buckets/{urllib.parse.quote(bucket_id)}/events", body=events)


def parse_ts(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def fingerprint(event):
    """Identity of an already-mirrored event.

    Start and app alone, at millisecond resolution: duration is deliberately
    excluded because the importer revises it. The last interval of a batch is
    stitched again when the next batch extends it, and matching on duration would
    file the extended copy as a new event and double-count the app.
    """
    ts = parse_ts(event["timestamp"]).astimezone(timezone.utc)
    return (ts.replace(microsecond=(ts.microsecond // 1000) * 1000), event["data"].get("app"))


def mirror_bucket(server, source_id, host, lookback, dry_run):
    window_id = f"aw-watcher-window_{host}"
    afk_id = f"aw-watcher-afk_{host}"

    if dry_run:
        fresh = window_id not in server.buckets()
    else:
        fresh = server.create_bucket(window_id, WINDOW_TYPE, host)
        server.create_bucket(afk_id, AFK_TYPE, host)

    now = datetime.now(timezone.utc)
    # A bucket this run created has no history to be consistent with, so take the
    # lot; steady state only needs the window where backfills still land.
    start = datetime(2000, 1, 1, tzinfo=timezone.utc) if fresh else now - lookback

    source = server.events(source_id, start, now)
    if not source:
        return 0

    # A dry run against a bucket that does not exist yet has nothing to ask for.
    prior = [] if (dry_run and fresh) else server.events(window_id, start, now)
    seen = {fingerprint(e) for e in prior}
    window_events, afk_events = [], []
    for event in source:
        if fingerprint(event) in seen:
            continue
        app = event["data"].get("app")
        window_events.append(
            {
                "timestamp": event["timestamp"],
                "duration": event["duration"],
                # A quarter of Screen Time events carry no title -- App Store
                # enrichment simply misses some bundles. Empty titles would render
                # as a blank row in Top Window Titles, so fall back to the bundle
                # id, which is at least identifying.
                "data": {"app": app, "title": event["data"].get("title") or app},
            }
        )
        afk_events.append(
            {
                "timestamp": event["timestamp"],
                "duration": event["duration"],
                "data": {"status": "not-afk"},
            }
        )

    if dry_run:
        print(f"{host}: would mirror {len(window_events)} of {len(source)} events")
        return len(window_events)

    server.insert(window_id, window_events)
    server.insert(afk_id, afk_events)
    print(f"{host}: mirrored {len(window_events)} of {len(source)} events in range")
    return len(window_events)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--server", default="http://127.0.0.1:5600")
    ap.add_argument(
        "--lookback-hours",
        type=float,
        default=72.0,
        help="how far back each pass rescans for late-arriving events",
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    server = Server(args.server)
    lookback = timedelta(hours=args.lookback_hours)

    total = 0
    for bucket_id, bucket in sorted(server.buckets().items()):
        if not bucket_id.startswith(SOURCE_PREFIX):
            continue
        # Devices that never reported. Screen Time lists every Apple device ever
        # signed in, including retired phones whose Biome stream stopped years
        # ago, and mirroring those would invent hosts in the UI's dropdown that
        # can only ever show an empty day.
        if bucket["metadata"].get("end") is None:
            continue
        total += mirror_bucket(server, bucket_id, bucket["hostname"], lookback, args.dry_run)

    if total == 0:
        print("nothing to mirror")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except urllib.error.URLError as err:
        # The timer retries in ten minutes and Screen Time data is already tens of
        # minutes stale, so a server that is briefly down is not worth a failed
        # unit in the journal.
        print(f"activitywatch unreachable: {err}", file=sys.stderr)
        sys.exit(0)
