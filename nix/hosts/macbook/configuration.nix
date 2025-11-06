{
  pkgs,
  stateVersion,
  userdata,
  inputs,
  ...
}: {
  imports = [
    ../shared/nix-config.nix
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [pkgs.neovim pkgs.git];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = stateVersion;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform;

  users.users.${userdata.username} = {
    description = "${userdata.name}";
    home = "/Users/${userdata.username}";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYi6b9Qaa6hF5PXkaTinS131ESVKDkQTOWCcvD8JmZ3"
    ];
  };

  system.primaryUser = "${userdata.username}";

  # MacOS Workspace Switching Configuration
  #
  # This configuration sets up keyboard shortcuts for switching between workspaces/desktops
  # using the Option (Alt) key + number combinations.
  #
  # Modifier Key Values:
  # - None:           0
  # - Shift:          131072
  # - Control:        1048576
  # - Option/Alt:     524288
  # - Command:        1048840
  # - Command+Shift:  1179914
  #
  # Key Codes (first parameter):
  # - 1: 49    - 6: 54
  # - 2: 50    - 7: 55
  # - 3: 51    - 8: 56
  # - 4: 52    - 9: 57
  # - 5: 53    - 0: 58
  #
  # Virtual Keycodes (second parameter):
  # - 1: 18    - 6: 23
  # - 2: 19    - 7: 24
  # - 3: 20    - 8: 25
  # - 4: 21    - 9: 26
  # - 5: 22    - 0: 27
  #
  # Symbolic Hotkey IDs:
  # - 118: Switch to Desktop 1    - 122: Switch to Desktop 5
  # - 119: Switch to Desktop 2    - 123: Switch to Desktop 6
  # - 120: Switch to Desktop 3    - 124: Switch to Desktop 7
  # - 121: Switch to Desktop 4    - 125: Switch to Desktop 8
  #
  # Other Useful IDs:
  # - 32: Mission Control
  # - 33: Application Windows
  # - 36: Move Left a Space
  # - 37: Move Right a Space
  #
  # To debug current settings:
  # $ defaults read com.apple.symbolichotkeys.plist AppleSymbolicHotKeys
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "118" = {
          enabled = true;
          value = {
            parameters = [49 18 524288]; # Option + 1
            type = "standard";
          };
        };
        "119" = {
          enabled = true;
          value = {
            parameters = [50 19 524288]; # Option + 2
            type = "standard";
          };
        };
        "120" = {
          enabled = true;
          value = {
            parameters = [51 20 524288]; # Option + 3
            type = "standard";
          };
        };
        "121" = {
          enabled = true;
          value = {
            parameters = [52 21 524288]; # Option + 4
            type = "standard";
          };
        };
        "122" = {
          enabled = true;
          value = {
            parameters = [53 21 524288]; # Option + 5
            type = "standard";
          };
        };
        # Mission Control Option + tab
        "32" = {
          enabled = true;
          value = {
            parameters = [65535 48 524288]; # 48 is Tab key
            type = "standard";
          };
        };
        # Input Source switching Option + space
        "60" = {
          enabled = true;
          value = {
            parameters = [49 49 524288]; # 49 is Space, 524288 is Option modifier
            type = "standard";
          };
        };
        # Selected screenshot (Option + Shift + S)
        "31" = {
          enabled = true;
          value = {
            parameters = [115 1 655360]; # 1 is 'S', 655360 is Option(524288) + Shift(131072)
            type = "standard";
          };
        };
      };
    };
    "com.googlecode.iterm2" = {
      "PrefsCustomFolder" = "/Users/${userdata.username}/.config/iterm";
      "LoadPrefsFromCustomFolder" = 1;
    };
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

    # example of adding a tap
    # taps = ["homebrew/cask-fonts" "dimentium/autoraise" "nikitabobko/tap" "homebrew/services"];
    taps = [];

    # `brew install`
    # Example of installing a package and starting a service
    # brews = [
    #   autoraise to implement focus follow mouse in aerospace
    #   {
    #     name = "autoraise";
    #     start_service = true;
    #     restart_service = true;
    #   }
    # ];
    brews = [
      "displayplacer"
      "libmagic"
      "uv"
    ];

    # `brew install --cask`
    casks = [
      "iterm2"
      "1password"
      "spotify"
      "alt-tab"
      "signal"
      "messenger"
      "obsidian"
      "discord"
      "monitorcontrol"
      "unnaturalscrollwheels"
      "rectangle"
      "activitywatch"
      "vlc"
      "google-chrome"
    ];
    global.autoUpdate = true;
  };
  system.defaults.dock = {
    autohide = true;
  };
  system.defaults.finder = {
    AppleShowAllFiles = true;
    CreateDesktop = false;
    FXDefaultSearchScope = "SCcf";
    FXEnableExtensionChangeWarning = false;
    FXPreferredViewStyle = "Nlsv";
    QuitMenuItem = true;
    ShowPathbar = true;
    ShowStatusBar = true;
    _FXShowPosixPathInTitle = true;
    _FXSortFoldersFirst = true;
  };
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  services.tailscale = {
    enable = true;
  };

  # from
  # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
  # If you configure some of your MacOS preferences via nix-darwin and then activate your system,
  # you’ll find that some of them don’t take effect until you logout or restart your system.
  # This option fixes that
  system.activationScripts.postActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
