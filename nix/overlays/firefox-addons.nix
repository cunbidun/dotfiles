final: prev: {
  nur.repos.rycee.firefox-addons =
    prev.nur.repos.rycee.firefox-addons
    // {
      carrot = prev.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon rec {
        pname = "carrot";
        version = "0.6.8";
        url = "https://addons.mozilla.org/firefox/downloads/file/4450645/carrot-${version}.xpi";
        sha256 = "sha256-4QXp97JyqBBHcZbCReEzKCltTBc8WShETjVXYjq2WZ0";
        addonId = "{f0eeb71a-e5d6-48e6-a818-568a6bef1bc0}";
        meta = {
        };
      };
    };
}
