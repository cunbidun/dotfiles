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
        exec = "${pkgs.chromium}/bin/chromium --profile-directory=${profile} --app=${url}";
        terminal = false;
        categories = ["Network"];
        startupNotify = false;
      }
      // lib.optionalAttrs (icon != null) {inherit icon;};
  in
    lib.nameValuePair (lib.toLower name) desktopEntry;
in {
  programs.chromium = {
    enable = true;
    extensions = [
      # uBlock Origin
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";}
      # SponsorBlock
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";}
      # Vimium
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}
      # Competitive Companion
      {id = "cjnmckjndlpiamhfimnnjmnckgghkjbl";}
      # multi-account-containers has no Chromium equivalent
      # 1Password – Password Manager
      {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";}
      # User-Agent Switcher
      {id = "jkafdamincoabdjebhjmbiflploojgjf";}
      # ActivityWatch Web watcher
      {id = "nglaklhklhcoonedhgnpgddginnjdadi";}
      # KeePassHelper
      {id = "jgnfghanfbjmimbdmnjfofnbcgpkbegj";}
      # Tampermonkey
      {id = "dhdgffkkebhmkfjojejmpbldmpobfkfo";}
      # Unhook – Remove YouTube Recommendations
      {id = "khncfooichmfjbepaaaebmommgaepoid";}
      # Carrot (contest rating predictor)
      {id = "gakohpplicjdhhfllilcjpfildodfnnn";}
    ];
  };

  # add xdg entries for PWAs
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
