{
  config,
  pkgs,
  lib,
  project_root,
  ...
}: let
  searchPolicy = {
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderKeyword = "ddg";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
    DefaultSearchProviderIconURL = "https://duckduckgo.com/favicon.ico";
    DefaultSearchProviderEncodings = ["UTF-8"];
    DefaultSearchProviderAlternateURLs = ["https://duckduckgo.com/?q={searchTerms}"];
    ManagedSearchEngines = [
      {
        name = "DuckDuckGo";
        keyword = "ddg";
        search_url = "https://duckduckgo.com/?q={searchTerms}";
        suggest_url = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
        favicon_url = "https://duckduckgo.com/favicon.ico";
        encodings = ["UTF-8"];
        is_default = true;
      }
      {
        name = "GitHub Repositories";
        keyword = "@gh";
        search_url = "https://github.com/search?q={searchTerms}&type=repositories";
        favicon_url = "https://github.githubassets.com/favicons/favicon.png";
        encodings = ["UTF-8"];
      }
      {
        name = "Nix Packages";
        keyword = "@nix";
        search_url = "https://search.nixos.org/packages?type=packages&query={searchTerms}";
        favicon_url = "https://nixos.org/favicon.png";
        encodings = ["UTF-8"];
      }
      {
        name = "Home Manager";
        keyword = "@hm";
        search_url = "https://rycee.gitlab.io/home-manager/options.html#{searchTerms}";
        encodings = ["UTF-8"];
      }
    ];
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
  xdg.configFile."chromium/policies/managed/search-engines.json" = {
    force = true;
    text = builtins.toJSON searchPolicy;
  };
}
