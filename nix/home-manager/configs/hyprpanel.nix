{
  lib,
  pkgs,
  config,
  ...
}: let
  repoPath = "${config.home.homeDirectory}/dotfiles/nix/hyprpanel";
  agsProjectPath = "${config.home.homeDirectory}/.config/ags/hyprpanel";
  stylixStatePath = "${config.home.homeDirectory}/.local/state/stylix";

  runtimeDeps = with pkgs;
    [
      ags

      astal.apps
      astal.battery
      astal.bluetooth
      astal.cava
      astal.hyprland
      astal.io
      astal.mpris
      astal.network
      astal.notifd
      astal.powerprofiles
      astal.tray
      astal.wireplumber

      bluez
      bluez-tools
      bash
      btop
      coreutils
      dart-sass
      findutils
      glib
      glib-networking
      gnome-bluetooth
      gawk
      gnugrep
      gnused
      grimblast
      gtksourceview3
      gvfs
      hyprpicker
      libgtop
      libnotify
      libsoup_3
      networkmanager
      pywal
      procps
      swww
      upower
      wireplumber
      wl-clipboard
      systemd
      which

      (python3.withPackages (ps: with ps; [dbus-python pygobject3]))
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      gpu-screen-recorder
    ];

  giTypelibPath = lib.makeSearchPathOutput "lib" "lib/girepository-1.0" runtimeDeps;
  libPath = lib.makeLibraryPath runtimeDeps;
  binPath = lib.makeBinPath runtimeDeps;
  depPaths = lib.concatStringsSep " " (map toString runtimeDeps);

  agsRunScript = pkgs.writeShellScriptBin "ags-run-hyprpanel" ''
    set -eo pipefail

    export GIO_EXTRA_MODULES='${pkgs.glib-networking}/lib/gio/modules'
    if [ -n "''${GI_TYPELIB_PATH:-}" ]; then
      export GI_TYPELIB_PATH='${giTypelibPath}':"$GI_TYPELIB_PATH"
    else
      export GI_TYPELIB_PATH='${giTypelibPath}'
    fi

    if [ -n "''${LD_LIBRARY_PATH:-}" ]; then
      export LD_LIBRARY_PATH='${libPath}':"$LD_LIBRARY_PATH"
    else
      export LD_LIBRARY_PATH='${libPath}'
    fi
    export PATH='${binPath}:$PATH'

    xdg_data_dirs=()
    for dep in ${depPaths}; do
      if [ -d "$dep/share" ]; then
        xdg_data_dirs+=("$dep/share")
      fi
      if [ -d "$dep/share/gsettings-schemas" ]; then
        for schema_root in "$dep"/share/gsettings-schemas/*; do
          if [ -d "$schema_root" ]; then
            xdg_data_dirs+=("$schema_root")
          fi
        done
      fi
    done
    if [ "''${#xdg_data_dirs[@]}" -gt 0 ]; then
      export XDG_DATA_DIRS="$(IFS=:; echo "''${xdg_data_dirs[*]}")''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    fi

    cd '${agsProjectPath}'
    exec ${pkgs.ags}/bin/ags run app.ts
  '';

  agsWatchScript = pkgs.writeShellScript "ags-watch-hyprpanel" ''
    set -euo pipefail

    watch_dir='${agsProjectPath}'
    stylix_state_dir='${stylixStatePath}'
    last_restart=0
    debounce_ms=800

    watch_targets=("$watch_dir")
    if [ -L "$watch_dir" ]; then
      watch_dir="$(readlink -f "$watch_dir")"
      watch_targets=("$watch_dir")
    fi
    if [ -d "$stylix_state_dir" ]; then
      watch_targets+=("$stylix_state_dir")
    fi

    while ${pkgs.inotify-tools}/bin/inotifywait \
      --quiet \
      --recursive \
      --event close_write,delete,move \
      --exclude '(^|/)(\\.git|node_modules|dist|config)(/|$)|(^|/)\\.goutputstream-.*|(~$|\\.sw.$)' \
      "''${watch_targets[@]}"; do
      now_ms="$(${pkgs.coreutils}/bin/date +%s%3N)"
      if [ "$last_restart" -ne 0 ] && [ "$((now_ms - last_restart))" -lt "$debounce_ms" ]; then
        continue
      fi
      last_restart="$now_ms"
      ${pkgs.systemd}/bin/systemctl --user restart ags.service || true
    done
  '';
in {
  # Make the AGS source mutable in-place via out-of-store symlink.
  xdg.configFile."ags/hyprpanel" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink repoPath;
  };

  home.packages = [
    pkgs.ags
  ];

  systemd.user.services.ags = {
    Unit = {
      Description = "AGS (HyprPanel config from source)";
      After = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = lib.getExe agsRunScript;
      Environment = [
        "HYPRPANEL_CONFIG_DIR=${agsProjectPath}/config"
      ];
      KillMode = "mixed";
      TimeoutStopSec = 2;
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.ags-watch = {
    Unit = {
      Description = "Watch AGS HyprPanel source and restart AGS on change";
      After = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.bash}/bin/bash ${agsWatchScript}";
      Restart = "always";
      RestartSec = 1;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
