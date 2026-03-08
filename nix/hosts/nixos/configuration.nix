# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  userdata,
  lib,
  ...
}: let
  brightnessctlDdcutil = pkgs.writeShellScriptBin "brightnessctl" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ddc="${pkgs.ddcutil}/bin/ddcutil"
    class="backlight"
    [ "''${1:-}" = "-c" ] && class="$2" && shift 2
    [ "$class" = "backlight" ] || { echo "Failed to read any devices of class '$class'." >&2; exit 1; }
    lock_file="/tmp/brightnessctl-ddcutil.lock"
    exec 9>"$lock_file"
    flock -w 2 9 || { echo "DDC bus busy." >&2; exit 1; }

    bus_cache="/tmp/brightnessctl-ddcutil-bus"
    state_cache="/tmp/brightnessctl-ddcutil-state"
    bus="''${BRIGHTNESSCTL_DDCUTIL_BUS:-}"
    if [ -z "$bus" ] && [ -r "$bus_cache" ]; then
      bus="$(head -n1 "$bus_cache" | tr -cd '0-9')"
    fi
    if [ -z "$bus" ]; then
      detect="$($ddc detect --brief 2>/dev/null || true)"
      while IFS= read -r line; do
        case "$line" in
          *"/dev/i2c-"*)
            bus="''${line##*/dev/i2c-}"
            bus="''${bus%%[^0-9]*}"
            break
            ;;
        esac
      done <<<"$detect"
      [ -n "$bus" ] && printf '%s\n' "$bus" > "$bus_cache" 2>/dev/null || true
    fi
    [ -n "$bus" ] || { echo "No DDC/CI display found." >&2; exit 1; }

    get_vals() {
      local out cur max
      out="$($ddc --bus "$bus" --skip-ddc-checks --sleep-multiplier 0.1 --terse getvcp 10 2>/dev/null || true)"
      read -r _ _ _ cur max <<<"$out"
      [ -n "''${cur:-}" ] && [ -n "''${max:-}" ] || return 1
      printf '%s %s\n' "$cur" "$max"
    }

    read_cache() {
      local cur max cache_bus
      [ -r "$state_cache" ] || return 1
      read -r cur max cache_bus < "$state_cache" || return 1
      [[ "$cur" =~ ^[0-9]+$ ]] || return 1
      [[ "$max" =~ ^[0-9]+$ ]] || return 1
      [ "$max" -gt 0 ] || return 1
      [ "$cache_bus" = "$bus" ] || return 1
      printf '%s %s\n' "$cur" "$max"
    }

    write_cache() {
      local cur max
      cur="$1"
      max="$2"
      printf '%s %s %s\n' "$cur" "$max" "$bus" > "$state_cache"
    }

    refresh_cache_async() {
      (
        out="$($ddc --bus "$bus" --skip-ddc-checks --sleep-multiplier 0.1 --terse getvcp 10 2>/dev/null || true)"
        read -r _ _ _ cur max <<<"$out"
        [[ "''${cur:-}" =~ ^[0-9]+$ ]] || exit 0
        [[ "''${max:-}" =~ ^[0-9]+$ ]] || exit 0
        [ "$max" -gt 0 ] || exit 0
        write_cache "$cur" "$max"
      ) >/dev/null 2>&1 &
    }

    case "''${1:-}" in
      -m)
        if ! read -r cur max < <(read_cache); then
          read -r cur max < <(get_vals) || { echo "Error reading device: No such file or directory" >&2; exit 1; }
          write_cache "$cur" "$max"
        fi
        pct=$(( cur * 100 / max ))
        printf 'ddcutil::i2c-%s,backlight,%s,%s%%,%s\n' "$bus" "$cur" "$pct" "$max"
        ;;
      set)
        arg="''${2:-}"
        [ -n "$arg" ] || { echo "Usage: brightnessctl set <value>" >&2; exit 1; }
        cached_cur=""
        cached_max=""
        if read -r cached_cur cached_max < <(read_cache); then
          true
        else
          cached_cur=0
          cached_max=100
        fi
        case "$arg" in
          +*%)
            n="''${arg#+}"
            n="''${n%%%}"
            $ddc --bus "$bus" --noverify --skip-ddc-checks --sleep-multiplier 0.1 setvcp 10 + "$n" >/dev/null
            target=$(( cached_cur + (cached_max * n / 100) ))
            [ "$target" -gt "$cached_max" ] && target="$cached_max"
            write_cache "$target" "$cached_max"
            refresh_cache_async
            exit 0
            ;;
          *%-)
            n="''${arg%%%-}"
            n="''${n%%%}"
            $ddc --bus "$bus" --noverify --skip-ddc-checks --sleep-multiplier 0.1 setvcp 10 - "$n" >/dev/null
            target=$(( cached_cur - (cached_max * n / 100) ))
            [ "$target" -lt 0 ] && target=0
            write_cache "$target" "$cached_max"
            refresh_cache_async
            exit 0
            ;;
          *%)
            n="''${arg%%%}"
            target=$(( cached_max * n / 100 ))
            ;;
          *) echo "Unsupported set value: $arg" >&2; exit 1 ;;
        esac
        $ddc --bus "$bus" --noverify --skip-ddc-checks --sleep-multiplier 0.1 setvcp 10 "$target" >/dev/null
        write_cache "$target" "$cached_max"
        refresh_cache_async
        ;;
      *)
        echo "Unsupported arguments: $*" >&2
        exit 1
        ;;
    esac
  '';
in {
  imports = [
    ./hardware-configuration.nix
    ../shared/nix-config.nix
    ../shared/common.nix
    inputs.sops-nix.nixosModules.sops
    inputs.opnix.nixosModules.default
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "uinput"
    "i2c-dev"
    "ip_tables"
    "iptable_nat"
  ];
  boot.blacklistedKernelModules = ["wacom"];

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # turn on for ollama
  # services.ollama = {
  #   package = pkgs.nixpkgs-master.ollama;
  #   enable = true;
  #   acceleration = "rocm";
  #   loadModels = [
  #     "gpt-oss:20b"
  #   ];
  #   environmentVariables = {
  #     HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  #     OLLAMA_CONTEXT_LENGTH = "16384";
  #   };
  # };
  # services.open-webui = {
  #   package = pkgs.nixpkgs-master.open-webui;
  #   enable = true;
  #   host = "0.0.0.0";
  #   port = 8000;
  #   environment = {
  #     WEBUI_AUTH = "False";
  #     ENABLE_SIGNUP = "False";
  #     ANONYMIZED_TELEMETRY = "False";
  #     BYPASS_MODEL_ACCESS_CONTROL = "True";
  #     DO_NOT_TRACK = "True";
  #     SCARF_NO_ANALYTICS = "True";
  #     FRONTEND_BUILD_DIR = "${config.services.open-webui.stateDir}/build";
  #     DATA_DIR = "${config.services.open-webui.stateDir}/data";
  #     STATIC_DIR = "${config.services.open-webui.stateDir}/static";
  #   };
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "i2c"
      "docker"
      "render"
      "video"
    ];
    packages = with pkgs; [
      jdk17
      xdg-utils
      desktop-file-utils

      # Container
      podman-tui
      docker-compose
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      rocmPackages.amdsmi

      # pkgs.winboat
    ];
  };

  # To search for packages run 'nix search'. For example, 'nix search nixpkgs bazel'
  environment.systemPackages =
    (with pkgs; [
      neovim
      git
      brightnessctlDdcutil
      ddcutil
      _1password-cli
      sops
      xdg-desktop-portal-termfilechooser
    ])
    ++ [
      inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  services.onepassword-secrets = {
    enable = true;
    users = [userdata.username];
    secrets.sopsAgeKey = {
      reference = "op://Infrastructure/SOPS Age Key/private key";
      path = "/var/lib/sops-nix/keys.txt";
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  # Ensure OpNix waits for actual connectivity before contacting 1Password
  systemd.services.opnix-secrets = {
    after = ["network-online.target" "NetworkManager-wait-online.service"];
    wants = ["network-online.target" "NetworkManager-wait-online.service"];
  };

  sops = {
    defaultSopsFile = ../../../secrets/global.yaml;
    age.keyFile = config.services.onepassword-secrets.secretPaths.sopsAgeKey;
    secrets.geolocation = {
      path = "/etc/geolocation";
      owner = "geoclue";
      group = "geoclue";
      mode = "0666";
    };
    secrets.hyprpanel_weather_api_key = {
      sopsFile = ../../../secrets/hyprpanel.yaml;
      path = "/etc/hyprpanel/weather_api_key";
      owner = userdata.username;
      group = "users";
      mode = "0400";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.dconf.enable = true;
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = true;
  };
  programs.uwsm.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --asterisks --time --time-format '%A, %B %e, %Y -- %I:%M:%S %p' --cmd 'uwsm start default'";
  };
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;

  security.sudo.extraRules = [
    {
      users = [userdata.username];
      commands = [
        {
          command = "/run/current-system/sw/bin/reboot";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", TAG+="uaccess"
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  security.pam.services.hyprlock = {};
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  virtualisation.podman = {
    enable = true;
    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };
  services.usbmuxd.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = ["${userdata.username}"];
  };
  security.polkit.adminIdentities = [
    "unix-group:wheel"
  ];
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        (action.id == "org.freedesktop.login1.suspend" ||
         action.id == "org.freedesktop.login1.suspend-multiple-sessions")
        && subject.isInGroup("wheel")
      ) {
        return polkit.Result.YES;
      }
    });
  '';
  services.gnome.gnome-keyring.enable = true;

  environment.etc =
    {
      "flake-source".source = inputs.self;
      # Symlink to user-generated Chrome policy (generated by home-manager specialization)
      "opt/chrome/policies/managed/10-base.json".source = "/home/${userdata.username}/.local/etc/chrome-policy.json";
    }
    // lib.optionalAttrs (!config.services.geoclue2.enableWifi) {
      "geolocation".source = config.sops.secrets.geolocation.path;
      "geoclue/conf.d/00-config.conf".text = ''
        [static-source]
        enable=true
      '';
    };

  hardware.i2c.enable = true;
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  # services.blueman.enable = true;
  # the following 3 options are for enable usb automount
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  # Chrome is trying to access power-related information but can't find the UPower service.
  services.upower.enable = true;
  services.geoclue2 = {
    enable = true;
    submitData = true;
    # TODO: Wifi appears to not working at the moment
    enableWifi = false;
    submissionUrl = "https://api.beacondb.net/v2/geosubmit";
    geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
  };

  hardware.opentabletdriver.enable = true;
  console = {
    earlySetup = true;
    packages = with pkgs; [terminus_font];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  # Enable Stylix for system-wide theming
  # The actual theme configuration is in home-manager/configs/stylix.nix
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/standardized-dark.yaml";
    targets = {
      chromium.enable = false;
    };
  };
  programs.localsend = {
    enable = true;
    openFirewall = true; # opens port 53317 for receiving
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
