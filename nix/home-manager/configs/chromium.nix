{
  config,
  pkgs,
  lib,
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
        exec = "${pkgs.chromium}/bin/chromium --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;
in {
  programs.chromium.enable = true;
  # Place .desktop app entries for common PWAs.
  xdg.desktopEntries = lib.listToAttrs [
    (mkChromePWA {
      name = "ChatGPT";
      url = "https://chat.openai.com/";
    })
  ];
}
