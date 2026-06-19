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
}: {
  imports = [
    ./hardware-configuration.nix
    ./windows.nix
    ../shared/nix-config.nix
    ../shared/common.nix
    ../shared/user-secrets.nix
    ../shared/monitoring.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    ddcci-driver
  ];
  boot.kernelModules = [
    "uinput"
    "i2c-dev"
    "ddcci"
    "ddcci-backlight"
    "ip_tables"
    "iptable_nat"
  ];
  boot.blacklistedKernelModules = ["wacom"];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

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
  environment.systemPackages = with pkgs; [
    neovim
    git
    brightnessctl
    _1password-cli
    sops
    xdg-desktop-portal-termfilechooser
  ];

  sops = {
    defaultSopsFile = ../../../secrets/system.yaml;
    age.keyFile = "/var/lib/sops-nix/keys.txt";
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
  programs.steam.enable = true;
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
    # Allow browser WebHID access to Keychron K4 HE interfaces.
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ENV{ID_VENDOR_ID}=="3434", ENV{ID_MODEL_ID}=="0e40", TAG+="uaccess", GROUP="input", MODE="0660"
  '';

  systemd.services.ddcci-backlight = {
    description = "Expose DDC/CI monitors as Linux backlight devices";
    after = ["systemd-modules-load.service"];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ddcci-backlight-bind" ''
        set -euo pipefail

        stop_timer() {
          ${pkgs.systemd}/bin/systemctl stop ddcci-backlight.timer || true
        }

        has_backlight() {
          for brightness in /sys/class/backlight/ddcci*/brightness; do
            [ -e "$brightness" ] && return 0
          done
          return 1
        }

        if has_backlight; then
          stop_timer
          exit 0
        fi

        state_dir="/run/ddcci-backlight"
        mkdir -p "$state_dir"

        for name in /sys/bus/i2c/devices/i2c-*/name; do
          [ -e "$name" ] || continue
          grep -q '^AMDGPU DM aux hw bus ' "$name" || continue

          bus_dir="''${name%/name}"
          bus="''${bus_dir##*/}"
          node="$bus_dir/new_device"
          device="$bus_dir/''${bus#i2c-}-0037"
          ddcci_device="/sys/bus/ddcci/devices/ddcci''${bus#i2c-}"
          delete="$bus_dir/delete_device"
          marker="$state_dir/$bus"

          if [ -e "$device" ]; then
            if has_backlight; then
              stop_timer
              exit 0
            fi

            if [ -e "$marker" ] && [ -w "$delete" ]; then
              echo 0x37 > "$delete" || true
              rm -f "$marker"
              for _ in 1 2 3 4 5 6 7 8 9 10; do
                [ ! -e "$ddcci_device" ] && break
                sleep 0.1
              done
            else
              touch "$marker"
            fi
          fi

          if [ -w "$node" ] && [ ! -e "$device" ] && [ ! -e "$ddcci_device" ]; then
            echo ddcci 0x37 > "$node" || true
          fi
        done

        if has_backlight; then
          stop_timer
        fi
      '';
    };
  };

  systemd.timers.ddcci-backlight = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1s";
      OnUnitActiveSec = "1s";
      AccuracySec = "100ms";
      Unit = "ddcci-backlight.service";
    };
  };

  security.pam.services.hyprlock = {};
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig."10-bluez-no-headset-autoswitch" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
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
    appConfig."hyprsunset-geoclue" = {
      isAllowed = true;
      isSystem = false;
    };
  };

  # Don't start geoclue if the sops secret hasn't been decrypted yet
  systemd.services.geoclue.unitConfig.ConditionPathExists = "/etc/geolocation";

  hardware.opentabletdriver.enable = true;
  console = {
    earlySetup = true;
    packages = with pkgs; [terminus_font];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };

  # Enable Stylix for system-wide theming
  # The actual theme configuration is in home-manager/configs/stylix.nix
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/standardized-dark.yaml";
    targets = {
      chromium.enable = false;
      kmscon.enable = false;
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
