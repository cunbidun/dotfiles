{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  chromePackage = pkgs.google-chrome;
  chromeBinary = "${chromePackage}/bin/google-chrome-stable";

  # Import shared Chrome configuration
  chromeConfig = import ./shared/chrome-config.nix;
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
in {
  # add xdg entries for PWAs
  home.packages = lib.mkIf isLinux [
    # (pkgs.google-chrome.override {
    #   commandLineArgs = "--refresh-platform-policy";
    # })
    chromePackage
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
  };
  # Generate Chrome policy file in user home directory
  home.file.".local/etc/chrome-policy.json" = lib.mkIf isLinux {
    text = chromeConfig.mkChromePolicy chromeConfig.baseExtensions;
  };
  home.activation.refresh_chrome_policy = lib.mkIf isLinux ''
    ${chromeBinary} --refresh-platform-policy --no-startup-window || true
  '';
}
