{
  config,
  userdata,
  pkgs,
  lib,
  ...
}: {
  # Time zone
  time.timeZone = userdata.timeZone;

  # Locale settings
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

  # User configuration
  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.name;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  # Security
  security.polkit.enable = true;
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Tailscale
  services.tailscale.enable = true;

  # Docker
  virtualisation.docker.enable = true;

  # nix-ld for running unpatched binaries
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

  # Enable zsh
  programs.zsh.enable = true;
}
