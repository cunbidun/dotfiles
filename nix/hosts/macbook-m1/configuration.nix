{pkgs, ...}: {
  security.pam.enableSudoTouchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [pkgs.vim pkgs.git];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.cunbidun = {
    description = "Duy Pham";
    home = "/Users/cunbidun";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYi6b9Qaa6hF5PXkaTinS131ESVKDkQTOWCcvD8JmZ3"
    ];
  };
  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = ["homebrew/cask-fonts" "dimentium/autoraise" "nikitabobko/tap" "homebrew/services"];

    # `brew install`
    brews = [
      {
        name = "autoraise";
        start_service = true;
        restart_service = true;
      }
    ];

    # `brew install --cask`
    casks = [
      "1password"
      "spotify"
      "alt-tab"
      "google-chrome"
      "firefox"
      "signal"
      "messenger"
      "obsidian"
      "syncthing"
      "discord"
      "monitorcontrol"
      "font-sauce-code-pro-nerd-font"
      "unnaturalscrollwheels"
      "steam"
      "aerospace"
      "netnewswire"
      "raycast"
    ];
    global.autoUpdate = true;
  };
  system.defaults.dock = {
    autohide = true;
  };

  # from
  # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
  # If you configure some of your MacOS preferences via nix-darwin and then activate your system,
  # you’ll find that some of them don’t take effect until you logout or restart your system.
  # This option fixes that
  system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
