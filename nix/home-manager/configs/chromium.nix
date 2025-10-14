{
  config,
  pkgs,
  lib,
  project_root,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  chromeBinary = "${pkgs.chromium}/bin/chromium";
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
  home.packages = [
    pkgs.chromium
  ];
  xdg = lib.mkIf isLinux {
    dataFile."icons/hicolor/scalable/apps/messenger.svg".source = "${project_root}/icons/messenger.svg";
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
      "text/html" = ["google-chrome-unstable.desktop"];
      "text/xml" = ["google-chrome-unstable.desktop"];
      "x-scheme-handler/http" = ["google-chrome-unstable.desktop"];
      "x-scheme-handler/https" = ["google-chrome-unstable.desktop"];
    };
  };
  home.activation.refreshChromiumPolicy = lib.mkIf isLinux ''
    if [ -x "${chromeBinary}" ]; then
      "${chromeBinary}" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 || true
    fi
  '';
}
