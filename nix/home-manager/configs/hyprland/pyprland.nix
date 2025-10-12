{
  pkgs,
  lib,
  ...
}: let
  format = pkgs.formats.toml {};
  messengerDesktop = "messenger.desktop";
  messengerLauncher = pkgs.writeShellScript "launch-messenger-pwa" ''
    set -euo pipefail

    target=${lib.escapeShellArg messengerDesktop}

    declare -a search_roots=()

    IFS=':' read -r -a data_dirs <<< "''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for dir in "''${data_dirs[@]}"; do
      if [ -n "$dir" ]; then
        search_roots+=("$dir")
      fi
    done

    search_roots+=("/etc/profiles/per-user/$USER/share" "$HOME/.nix-profile/share")

    for root in "''${search_roots[@]}"; do
      candidate="$root/applications/$target"
      if [ -f "$candidate" ]; then
        exec ${pkgs.glib}/bin/gio launch "$candidate"
      fi
    done

    echo "Could not locate $target via known XDG data directories" >&2
    exit 1
  '';
in {
  xdg.configFile."hypr/pyprland.toml".source = format.generate "pyprland.toml" {
    pyprland = {
      plugins = [
        "scratchpads"
        "toggle_special"
      ];
    };
    scratchpads = {
      term = {
        command = "kitty --title Scratchpad";
        animation = "";
        lazy = true;
        unfocus = "";
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      messenger = {
        command = "${messengerLauncher}";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        class = "MessengerPWA";
        match_by = "initialClass";
        hysteresis = 0;
        process_tracking = false;
      };

      spotify = {
        command = "spotify";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      signal = {
        command = "signal-desktop";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        excludes = "*";
        hysteresis = 0;
      };

      file = {
        command = "kitty --title FileExplorer -- yazi";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "50% 50%";
        position = "25% 25%";
        hysteresis = 0;
      };

      obsidian = {
        command = "obsidian";
        animation = "";
        unfocus = "";
        lazy = true;
        size = "75% 75%";
        position = "12% 12%";
        excludes = "*";
        hysteresis = 0;
      };
    };
  };
}
