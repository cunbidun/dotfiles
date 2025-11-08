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
    ./uxplay.nix
    ../shared/nix-config.nix
    inputs.sops-nix.nixosModules.sops
    inputs.opnix.nixosModules.default
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Bootloader.
  boot.kernelPackages = pkgs.nixpkgs-stable.linuxPackages_6_12; # Use the LTS kernel for better stability.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = ["uinput" "i2c-dev" "ip_tables" "iptable_nat"];
  boot.blacklistedKernelModules = ["wacom"];

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = userdata.timeZone;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

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
    extraGroups = ["networkmanager" "wheel" "input" "i2c" "docker"];
    packages = with pkgs; [
      jdk17
      xdg-utils
      desktop-file-utils
      distrobox

      # Container
      podman-tui
      docker-compose
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      rocmPackages.amdsmi

      pkgs.winboat
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  # To search for packages run 'nix search'. For example, 'nix search nixpkgs bazel'
  environment.systemPackages =
    (with pkgs; [
      neovim
      git
      _1password-cli
      sops
    ])
    ++ [
      inputs.opnix.packages.${pkgs.system}.default
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

  sops = {
    defaultSopsFile = ../../../secrets/global.yaml;
    age.keyFile = config.services.onepassword-secrets.secretPaths.sopsAgeKey;
    secrets.geolocation = {
      path = "/etc/geolocation";
      owner = "geoclue";
      group = "geoclue";
      mode = "0666";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.dconf.enable = true;
  programs.zsh.enable = true;
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
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

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

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
  virtualisation = {
    podman = {
      enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings = {dns_enabled = true;};
    };
    docker.enable = true;
  };
  services.usbmuxd.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = ["${userdata.username}"];
  };
  # Enable Polkit
  security.polkit.enable = true;
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
    // lib.optionalAttrs (! config.services.geoclue2.enableWifi) {
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
  services.tailscale.enable = true;
  console = {
    earlySetup = true;
    packages = with pkgs; [terminus_font];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  };

  # TODO: Remove this once nixpkgs fixes the issue with podman OCI permissions
  # https://discourse.nixos.org/t/distrobox-podman-oci-permission-error/64943/10
  security.lsm = lib.mkForce [];

  # Sets up all the libraries to load
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      fuse3
      icu
      zlib
      nss
      openssl
      curl
      expat
    ];
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
