{
  config,
  pkgs,
  lib,
  project_root,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  mkChromiumProfile = {
    name,
    profileDir,
  }: let
    desktopName = lib.replaceStrings [" "] ["-"] (lib.toLower name);
  in
    lib.nameValuePair desktopName {
      name = desktopName;
      exec = "${pkgs.chromium}/bin/chromium --profile-directory=${profileDir}";
      terminal = false;
      categories = ["Network" "WebBrowser"];
      startupNotify = true;
      type = "Application";
    };

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
        exec = "${pkgs.chromium}/bin/chromium --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;
in {
  # add xdg entries for PWAs
  xdg = lib.mkIf isLinux {
    dataFile."icons/hicolor/scalable/apps/messenger.svg".source = "${project_root}/icons/messenger.svg";
    desktopEntries = lib.listToAttrs [
      (mkChromiumProfile {
        name = "Chromium Vi";
        profileDir = "${config.home.homeDirectory}/.config/chromium/extra-profiles/vi";
      })
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
}
