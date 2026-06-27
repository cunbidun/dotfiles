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
    chromePackage
  ];
  xdg = lib.mkIf isLinux {
    dataFile."icons/hicolor/scalable/apps/messenger.svg".source = ../../../../icons/messenger.svg;
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
      (mkChromePWA {
        name = "Instagram";
        url = "https://www.instagram.com/";
      })
      (mkChromePWA {
        name = "ChatGPT";
        url = "https://chatgpt.com/";
      })
    ];
  };
}
