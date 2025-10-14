{
  config,
  pkgs,
  lib,
  project_root,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  chromiumPackage =
    if isLinux
    then pkgs.chromium
    else pkgs.chromium;
  chromiumBin = "${chromiumPackage}/bin/chromium";
  chromiumDesktopId = "chromium.desktop";
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
        exec = "${chromiumBin} --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;
in {
  home.packages = lib.optionals isLinux [
    (pkgs.writeShellScriptBin "chromium" ''
      exec ${chromiumBin} "$@"
    '')
  ];
  # add xdg entries for PWAs
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
      "text/html" = [chromiumDesktopId];
      "text/xml" = [chromiumDesktopId];
      "x-scheme-handler/http" = [chromiumDesktopId];
      "x-scheme-handler/https" = [chromiumDesktopId];
    };
  };
  home.activation.refreshChromiumPolicy = lib.mkIf isLinux ''
    if [ -x "${chromiumBin}" ]; then
      "${chromiumBin}" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 || true
    fi
  '';
}
