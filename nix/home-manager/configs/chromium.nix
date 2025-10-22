{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  chromeBinary = "${pkgs.google-chrome}/bin/google-chrome-stable";
  
  # Import shared Chrome configuration
  chromeConfig = import ./shared/chrome-config.nix;
  baseExtensions = chromeConfig.baseExtensions;
  
  mkChromePWA = {
    name,
    url,
    icon ? null,
    profile ? "Default",
  }: let
    desktopEntry =
      {
        inherit name;
        comment = "${name} PWA via Chrome";
        exec = "${chromeBinary} --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;

  # Generate Chrome policy JSON
  chromePolicyJson = chromeConfig.mkChromePolicy baseExtensions;
in {
  # add xdg entries for PWAs
  home.packages = lib.mkIf isLinux [
    pkgs.google-chrome
  ];
  xdg = lib.mkIf isLinux {
    dataFile."icons/hicolor/scalable/apps/messenger.svg".source = ../../../icons/messenger.svg;
    desktopEntries = lib.listToAttrs [
      (mkChromePWA {
        name = "Messenger";
        url = "https://www.messenger.com/";
        icon = "messenger";
      })
      (mkChromePWA {
        name = "Zalo";
        url = "https://chat.zalo.me/";
      })
    ];

    mimeApps.defaultApplications = {
      "text/html" = ["google-chrome-stable.desktop"];
      "text/xml" = ["google-chrome-stable.desktop"];
      "x-scheme-handler/http" = ["google-chrome-stable.desktop"];
      "x-scheme-handler/https" = ["google-chrome-stable.desktop"];
    };
  };

  # Generate Chrome policy file in user home directory
  home.file.".local/etc/chrome-policy.json" = lib.mkIf isLinux {
    text = chromePolicyJson;
  };
}
