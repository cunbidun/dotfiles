{
  config,
  pkgs,
  lib,
  project_root,
  ...
}: let
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
        exec = "${pkgs.chromium}/bin/chromium --class=${name}PWA --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;
in {
  programs.chromium.enable = true;
  xdg.dataFile."icons/hicolor/scalable/apps/messenger.svg".source = "${project_root}/icons/messenger.svg";
  xdg.desktopEntries = lib.listToAttrs [
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
}
