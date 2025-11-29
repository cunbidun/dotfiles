# Overlay for mac-default-browser
# Source is managed via flake input `mac-default-browser`
inputs: final: prev: {
  mac-default-browser = final.buildGoModule {
    pname = "default-browser";
    version = inputs.mac-default-browser.shortRev or "1.0.18";
    src = inputs.mac-default-browser;
    vendorHash = "sha256-m9bVRJua+YW2Zgp0GSRbrdKxQzoKMcYWo9DNHQNF1oU=";
    ldflags = ["-s" "-w" "-X main.version=1.0.18"];
    meta = with final.lib; {
      description = "CLI for setting the default browser on macOS";
      homepage = "https://github.com/macadmins/default-browser";
      license = licenses.mit;
      platforms = platforms.darwin;
    };
  };
}
