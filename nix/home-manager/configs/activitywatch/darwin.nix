# ActivityWatch watcher role for darwin -- the same job ./default.nix does on
# Linux (produce activity, store none of it), rebuilt on launchd because none of
# that file transfers: awatcher is an X11/Wayland tool with nothing to read on
# macOS, and systemd user units do not exist here.
#
# The watchers come from the ActivityWatch cask declared in
# hosts/macbook/configuration.nix, so this module points at /Applications rather
# than the nix store. nixpkgs' activitywatch is Linux-only, and reading the
# frontmost window here means calling the macOS Accessibility API from a signed
# bundle, which is not something a nix build can produce.
#
# Why aw-qt supervises instead of launchd running the two watchers directly --
# two independent reasons, both discovered the hard way:
#
#   TCC. Reading window titles needs Accessibility, and macOS attributes that
#   permission to the launchd job's executable. Run a watcher (or a wrapper
#   script) directly and the grant attaches to that exact path -- for a wrapper,
#   a /nix/store/...-bash path that silently loses the permission the next time
#   nixpkgs bumps bash, leaving the watcher running and posting nothing.
#   aw-qt is the bundle's CFBundleExecutable and signs as
#   net.activitywatch.ActivityWatch, so the grant lands on the app itself and
#   survives rebuilds.
#
#   Parenthood. aw-watcher-afk exits as soon as it sees getppid() == 1, a guard
#   against outliving the aw-qt that normally spawns it. Under launchd that is
#   the state it starts in, so run directly it dies on its first poll. With
#   aw-qt in the middle it has the parent it expects.
{
  config,
  lib,
  userdata,
  ...
}: let
  endpoint = import ./endpoint.nix;

  # Qualified, unlike the Linux units: see the note in ./endpoint.nix -- the bare
  # name resolves to home-server's LAN address on this host, where 5600 is shut.
  host = "${endpoint.host}.${userdata.tailnetDomain}";

  bundle = "/Applications/ActivityWatch.app/Contents/MacOS";

  # Screen Time importer, checked out and built with uv outside nix. Three
  # reasons it cannot live in the store, in descending order of how much they
  # hurt:
  #
  #   Full Disk Access. The iOS data sits under ~/Library/Biome, which is TCC
  #   protected -- a launchd agent without FDA gets "Operation not permitted"
  #   even though the files are mode 700 and its own. macOS attaches FDA to the
  #   executed binary, which for a python program is the interpreter, so a store
  #   path would lose the grant the next time nixpkgs bumps python and the agent
  #   would keep running while silently reading nothing. Hence a fixed prefix,
  #   and hence its own copied interpreter under ./python rather than the shared
  #   uv one: the grant is then both permanent and scoped to this tool alone.
  #
  #   Packaging. ccl-segb, which decodes Apple's SEGB stream format, is not in
  #   nixpkgs and is pulled straight from git by uv.
  #
  #   Precedent. Same reason ActivityWatch itself is a cask above.
  #
  # Bootstrap, once per machine:
  #
  #   git clone https://github.com/ActivityWatch/aw-import-screentime.git \
  #     ~/.local/share/aw-import-screentime
  #   cd ~/.local/share/aw-import-screentime
  #   cp -R ~/.local/share/uv/python/cpython-3.13.5-macos-aarch64-none ./python
  #   uv venv --python ./python/bin/python3.13 --no-managed-python
  #   uv sync --no-managed-python
  #
  # Then grant Full Disk Access to
  # ~/.local/share/aw-import-screentime/python/bin/python3.13 in System Settings
  # -> Privacy & Security, which no amount of nix can do for you: TCC.db is
  # SIP-protected and writable only through that pane.
  screentimeRoot = "${config.home.homeDirectory}/.local/share/aw-import-screentime";
in {
  # aw-qt starts its modules with no arguments beyond --testing, so unlike the
  # Linux watchers the server address cannot be passed on the command line --
  # this file is the only channel. It is written in full rather than patched so
  # that aw-core finds no missing keys and never tries to write back, which
  # against a read-only store symlink would fail.
  home.file."Library/Application Support/activitywatch/aw-client/aw-client.toml".text = ''
    [server]
    hostname = "${host}"
    port = "${toString endpoint.port}"

    [client]
    commit_interval = 10

    [server-testing]
    hostname = "127.0.0.1"
    port = "5666"

    [client-testing]
    commit_interval = 5
  '';

  launchd.agents.activitywatch = {
    enable = true;
    config = {
      ProgramArguments = [
        "${bundle}/aw-qt"
        # No tray icon: this is a daemon, and the menu it would add only offers
        # to start the local aw-server this host deliberately does not run.
        "--no-gui"
        # The whole point of the watcher role -- the default set includes
        # aw-server, which would start a second datastore next to home-server's.
        "--autostart-modules"
        "aw-watcher-afk,aw-watcher-window"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/activitywatch.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/activitywatch.log";
    };
  };

  # iPhone activity, by way of this Mac. Screen Time syncs App.InFocus telemetry
  # from every signed-in device into ~/Library/Biome via iCloud, so the phone
  # needs nothing installed on it -- but it also means events arrive on iCloud's
  # schedule (tens of minutes behind live), not as heartbeats. Needs "Share
  # Across Devices" on in Screen Time on both ends.
  #
  # No --host flag because there is none: the importer builds a plain
  # ActivityWatchClient, which reads the aw-client.toml written above, so it
  # follows the watchers to home-server automatically.
  launchd.agents.activitywatch-screentime = {
    enable = true;
    config = {
      ProgramArguments = ["${screentimeRoot}/.venv/bin/aw-import-screentime" "watch"];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aw-import-screentime.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aw-import-screentime.log";
    };
  };

  # No local-port forward, unlike ./default.nix. That exists on the desktop so
  # browser and editor extensions hardcoded to 127.0.0.1:5600 keep working; the
  # equivalent here would be a launchd socket listener, and nothing on this host
  # currently posts to localhost. Add it if a browser extension moves over.

  # The cask is what actually delivers the binaries above, so say so plainly
  # rather than leaving an agent crash-looping in a log nobody reads.
  home.activation.checkActivityWatchBundle = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -x ${bundle}/aw-qt ]; then
      echo "activitywatch: ${bundle}/aw-qt missing -- is the 'activitywatch' cask installed?" >&2
    fi
    # Neither of these can be repaired from nix -- the checkout needs the
    # network and the TCC grant needs a human in System Settings -- so the most
    # this can do is name the one command or click that fixes it.
    if [ ! -x ${screentimeRoot}/.venv/bin/aw-import-screentime ]; then
      echo "activitywatch: screentime importer missing -- see the bootstrap in ${toString ./darwin.nix}" >&2
    fi
  '';
}
