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
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./uxplay.nix
  ];

  # devenv wants users to be in the trusted-users list so that they can access the /nix/store

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings.trusted-users = ["root" "@wheel"];
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
        "https://yazi.cachix.org"
      ];
      trusted-substituters = [
        "https://hyprland.cachix.org"
        "https://yazi.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
    };
  };

  # Bootloader.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = ["uinput" "i2c-dev"];
  boot.blacklistedKernelModules = ["wacom"];

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.name;
    extraGroups = ["networkmanager" "wheel" "input" "i2c" "docker"];
    packages = with pkgs; [
      swaylock-effects
      jdk17
      xdg-utils
      desktop-file-utils
      distrobox

      # Container
      podman-tui
      docker-compose
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
  programs.uwsm.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --time-format '%A, %B %e, %Y -- %I:%M:%S %p' --cmd 'uwsm start default'";
  };

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
  security.pam.services.swaylock = {fprintAuth = false;};
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
  services.blueman.enable = true;
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
