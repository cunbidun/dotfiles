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
    inputs.winboat.nixosModules.default
    ./hardware-configuration.nix
    ./uxplay.nix
  ];
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  nix = {
    optimise.automatic = true;
    # TODO: this some how break 'nix develop'
    # https://github.com/maralorn/nix-output-monitor/issues/166
    # https://github.com/maralorn/nix-output-monitor/issues/140
    # package = inputs.nix-monitored.packages.${pkgs.system}.default;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = "nix-command flakes pipe-operators";
      accept-flake-config = true;
      builders-use-substitutes = true;
      trusted-users = ["root" "@wheel"]; # removed unused 'builder'
    };
  };

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
  #   package = pkgs.master.ollama;
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
  #   package = pkgs.master.open-webui;
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
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  # To search for packages run 'nix search'. For example, 'nix search nixpkgs bazel'
  environment.systemPackages = with pkgs; [
    neovim
    git
  ];

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
  programs.chromium = {
    enable = true;
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    extraOpts = {
      DefaultSearchProviderName = "DuckDuckGo";
      DefaultSearchProviderKeyword = "ddg";
      DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";
      DefaultSearchProviderEncodings = ["UTF-8"];
      DefaultSearchProviderAlternateURLs = ["https://duckduckgo.com/?q={searchTerms}"];
      ManagedSearchEngines = [
        {
          name = "DuckDuckGo";
          keyword = "ddg";
          search_url = "https://duckduckgo.com/?q={searchTerms}";
          suggest_url = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
          favicon_url = "https://duckduckgo.com/favicon.ico";
          encodings = ["UTF-8"];
          is_default = true;
        }
        {
          name = "GitHub Repositories";
          keyword = "@gh";
          search_url = "https://github.com/search?q={searchTerms}&type=repositories";
          favicon_url = "https://github.githubassets.com/favicons/favicon.png";
          encodings = ["UTF-8"];
        }
        {
          name = "Nix Packages";
          keyword = "@nix";
          search_url = "https://search.nixos.org/packages?type=packages&query={searchTerms}";
          favicon_url = "https://nixos.org/favicon.png";
          encodings = ["UTF-8"];
        }
        {
          name = "Home Manager";
          keyword = "@hm";
          search_url = "https://rycee.gitlab.io/home-manager/options.html#{searchTerms}";
          encodings = ["UTF-8"];
        }
      ];
      ExtensionSettings = {
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" = {
          toolbar_pin = "force_pinned";
        };
      };
    };
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
  services.gnome.gnome-keyring.enable = true;

  environment.etc =
    {
      "flake-source".source = inputs.self;
    }
    // lib.optionalAttrs (! config.services.geoclue2.enableWifi) {
      "geolocation".text = ''
        # Statue of Liberty
        40.6893129   # latitude
        -74.0445531  # longitude
        96           # altitude
        1.83         # accuracy radius
      '';
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

  services.winboat.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
