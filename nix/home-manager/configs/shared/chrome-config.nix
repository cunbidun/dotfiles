# Shared Chrome configuration constants
{
  # Base extensions that are always installed
  baseExtensions = [
    "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    "cjnmckjndlpiamhfimnnjmnckgghkjbl" # Competitive Companion
    "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password – Password Manager
    "jkafdamincoabdjebhjmbiflploojgjf" # User-Agent Switcher
    "nglaklhklhcoonedhgnpgddginnjdadi" # ActivityWatch Web watcher
    "jgnfghanfbjmimbdmnjfofnbcgpkbegj" # KeePassHelper
    "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
    "khncfooichmfjbepaaaebmommgaepoid" # Unhook – Remove YouTube Recommendations
    "gakohpplicjdhhfllilcjpfildodfnnn" # Carrot (contest rating predictor)
  ];

  # Generate Chrome policy JSON
  mkChromePolicy = extensionList: builtins.toJSON {
    ExtensionInstallForcelist = extensionList;
    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "DuckDuckGo";
    DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    BrowserLabsEnabled = false;
    RestoreOnStartup = 1;
    SiteSearchSettings = [
      {
        name = "GitHub Repositories";
        shortcut = "gh";
        url = "https://github.com/search?q={searchTerms}";
      }
      {
        name = "Nix Code";
        shortcut = "nc";
        url = "https://github.com/search?q={searchTerms}+NOT+is%3Afork+language%3ANix&type=code";
      }
      {
        name = "Nix Packages";
        shortcut = "nix";
        url = "https://search.nixos.org/packages?query={searchTerms}";
      }
    ];
    ExtensionSettings = {
      # 1Password
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" = {
        toolbar_pin = "force_pinned";
      };
      # competitive-companion
      "cjnmckjndlpiamhfimnnjmnckgghkjbl" = {
        toolbar_pin = "force_pinned";
      };
    };
  };
}