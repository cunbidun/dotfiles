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
  environment.systemPackages = [
    pkgs.neovim
    pkgs.git
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = stateVersion;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform;

  users.users.${userdata.username} = {
    description = userdata.name;
    home = "/Users/${userdata.username}";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = userdata.authorizedKeys or [];
  };

  system.primaryUser = "${userdata.username}";

  # MacOS Workspace Switching Configuration
  #
  # This configuration sets up keyboard shortcuts for switching between workspaces/desktops
  # and moving windows to specific workspaces using Option and Option+Shift key combinations.
  #
  # Symbolic Hotkey IDs Reference:
  # - Community documentation: https://github.com/mathiasbynens/dotfiles/blob/master/macos/defaults.sh
  # - macOS defaults reference: https://macos-defaults.com/
  # - To verify current settings: defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys
  #
  # Modifier Key Values:
  # - None:           0
  # - Shift:          131072
  # - Control:        1048576
  # - Option/Alt:     524288
  # - Command:        1048840
  # - Command+Shift:  1179914
  # - Option+Shift:   655360 (524288 + 131072)
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
  # - 118-122: Switch to Space 1-5 (Option + 1-5)
  # - 126-130: Move window to Space 1-5 (Option+Shift + 1-5)
  # - 32: Mission Control
  # - 33: Application Windows
  # - 36: Move Left a Space
  # - 37: Move Right a Space
  #
  # References & Verification:
  # - Apple does NOT officially document these IDs
  # - Sources: Reverse-engineered from ~/Library/Preferences/.GlobalPreferences.plist
  # - Community docs: https://github.com/mathiasbynens/dotfiles (main .macos file)
  # - Karabiner-Elements: https://github.com/pqrs-org/Karabiner-Elements
  # - macOS defaults: https://macos-defaults.com/
  #
  # To verify/extract IDs from your system:
  # $ defaults read .GlobalPreferences AppleSymbolicHotKeys
  # $ cat ~/Library/Preferences/.GlobalPreferences.plist | grep -A5 AppleSymbolicHotKeys
  #
  # TODO: Create script to verify these IDs match system defaults for this macOS version
  # TODO: Verify and add support for Spaces 6-8
  #
  # To debug current settings:
  # $ defaults read com.apple.symbolichotkeys.plist AppleSymbolicHotKeys
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Switch to Space (Option + 1-5)
        "118" = {
          enabled = true;
          value = {
            parameters = [
              49
              18
              524288
            ]; # Option + 1
            type = "standard";
          };
        };
        "119" = {
          enabled = true;
          value = {
            parameters = [
              50
              19
              524288
            ]; # Option + 2
            type = "standard";
          };
        };
        "120" = {
          enabled = true;
          value = {
            parameters = [
              51
              20
              524288
            ]; # Option + 3
            type = "standard";
          };
        };
        "121" = {
          enabled = true;
          value = {
            parameters = [
              52
              21
              524288
            ]; # Option + 4
            type = "standard";
          };
        };
        "122" = {
          enabled = true;
          value = {
            parameters = [
              53
              22
              524288
            ]; # Option + 5
            type = "standard";
          };
        };
        # Move window to Space (Option+Shift + 1-5)
        "126" = {
          enabled = true;
          value = {
            parameters = [
              49
              18
              655360
            ]; # Option+Shift + 1
            type = "standard";
          };
        };
        "127" = {
          enabled = true;
          value = {
            parameters = [
              50
              19
              655360
            ]; # Option+Shift + 2
            type = "standard";
          };
        };
        "128" = {
          enabled = true;
          value = {
            parameters = [
              51
              20
              655360
            ]; # Option+Shift + 3
            type = "standard";
          };
        };
        "129" = {
          enabled = true;
          value = {
            parameters = [
              52
              21
              655360
            ]; # Option+Shift + 4
            type = "standard";
          };
        };
        "130" = {
          enabled = true;
          value = {
            parameters = [
              53
              22
              655360
            ]; # Option+Shift + 5
            type = "standard";
          };
        };
        # Mission Control Option + tab
        "32" = {
          enabled = true;
          value = {
            parameters = [
              65535
              48
              524288
            ]; # 48 is Tab key
            type = "standard";
          };
        };
        # Input Source switching Option + space
        "60" = {
          enabled = true;
          value = {
            parameters = [
              49
              49
              524288
            ]; # 49 is Space, 524288 is Option modifier
            type = "standard";
          };
        };
        # Selected screenshot (Option + Shift + S)
        "31" = {
          enabled = true;
          value = {
            parameters = [
              115
              1
              655360
            ]; # 1 is 'S', 655360 is Option(524288) + Shift(131072)
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
      "aws-cdk"
    ];

    # `brew install --cask`
    casks = [
      "iterm2"
      "1password"
      "spotify"
      "alt-tab"
      "signal"
      "obsidian"
      "discord"
      "monitorcontrol"
      "unnaturalscrollwheels"
      "rectangle"
      "activitywatch"
      "vlc"
      "google-chrome"
      "redis-insight"
      "slack"
      "docker-desktop"
      "libreoffice"
      "datagrip"
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
  system.defaults.CustomUserPreferences.NSGlobalDomain.AppleReduceDesktopTinting = true;

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
