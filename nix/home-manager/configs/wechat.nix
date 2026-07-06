{pkgs, ...}: let
  fontsConf = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
  };

  launcherPrefix = pkgs.writeText "wechat-sandbox-prefix" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    uid="$(id -u)"
    gid="$(id -g)"
    host_runtime="''${XDG_RUNTIME_DIR:-/run/user/$uid}"
    sandbox_runtime="/run/user/$uid"
    sandbox_home="''${XDG_DATA_HOME:-$HOME/.local/share}/wechat-sandbox/home"
    wayland="''${WAYLAND_DISPLAY:-wayland-1}"

    if [ ! -S "$host_runtime/$wayland" ]; then
      echo "Wayland socket not found: $host_runtime/$wayland" >&2
      exit 1
    fi

    tmp="$(mktemp -d -t wechat-sandbox.XXXXXX)"
    cleanup() { rm -rf "$tmp"; }
    trap cleanup EXIT

    printf "wechat:x:%s:%s:WeChat Sandbox:/home/wechat:/bin/sh\n" "$uid" "$gid" > "$tmp/passwd"
    printf "wechat:x:%s:\n" "$gid" > "$tmp/group"
    printf "00000000000000000000000000000000\n" > "$tmp/machine-id"
    mkdir -p "$sandbox_home"

    extra_bwrap_args=(
      --dev-bind-try /dev/dri /dev/dri
      --tmpfs /home
      --bind "$sandbox_home" /home/wechat
      --dir /run
      --dir /run/user
      --dir "$sandbox_runtime"
      --bind "$host_runtime/$wayland" "$sandbox_runtime/$wayland"
      --ro-bind "$tmp/passwd" /etc/passwd
      --ro-bind "$tmp/group" /etc/group
      --ro-bind "$tmp/machine-id" /etc/machine-id
      --ro-bind-try /sys/class/net /sys/class/net
      --ro-bind-try /sys/devices/system/cpu /sys/devices/system/cpu
    )

    if [ -S "$host_runtime/pulse/native" ]; then
      extra_bwrap_args+=(
        --dir "$sandbox_runtime/pulse"
        --bind "$host_runtime/pulse/native" "$sandbox_runtime/pulse/native"
      )
    fi

    export HOME=/home/wechat
    export USER=wechat
    export LOGNAME=wechat
    export XDG_RUNTIME_DIR="$sandbox_runtime"
    export WAYLAND_DISPLAY="$wayland"
    export PULSE_SERVER="unix:$sandbox_runtime/pulse/native"
    unset DBUS_SESSION_BUS_ADDRESS
    export XDG_SESSION_TYPE=wayland
    export QT_QPA_PLATFORM=wayland
    export NIXOS_OZONE_WL=1
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export FONTCONFIG_FILE=${fontsConf}/etc/fonts/fonts.conf
    export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive
    export TZDIR=${pkgs.tzdata}/share/zoneinfo
    export TZ=America/New_York

    # patched from nixpkgs wechat launcher:
  '';

  wechatSandbox = pkgs.runCommand "wechat-sandbox" {nativeBuildInputs = [pkgs.makeWrapper];} ''
    mkdir -p "$out/bin" "$out/libexec"
    tail -n +2 ${pkgs.wechat}/bin/wechat > "$out/libexec/wechat-body"
    cat ${launcherPrefix} "$out/libexec/wechat-body" > "$out/libexec/wechat-sandbox-inner"
            chmod +x "$out/libexec/wechat-sandbox-inner"

            substituteInPlace "$out/libexec/wechat-sandbox-inner" \
          --replace-fail 'auto_mounts+=(--bind "$dir" "$dir")' ':' \
          --replace-fail 'etc_ignored=()' 'etc_ignored=(/etc/passwd /etc/group /etc/machine-id)' \
          --replace-fail '--dev-bind /dev /dev' '--dev /dev' \
              --replace-fail '--chdir "$(pwd)"' '--chdir /home/wechat' \
              --replace-fail '  "''${auto_mounts[@]}"' '  "''${extra_bwrap_args[@]}"'

            makeWrapper "$out/libexec/wechat-sandbox-inner" "$out/bin/wechat-sandbox"
  '';
in {
  home.packages = [wechatSandbox];

  xdg.enable = true;
  xdg.dataFile."applications/wechat.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=WeChat
    GenericName=Messenger
    Comment=WeChat in a Bubblewrap sandbox
    Exec=wechat-sandbox %u
    Icon=wechat
    Terminal=false
    Categories=Network;InstantMessaging;Chat;
    StartupWMClass=wechat
  '';
}
