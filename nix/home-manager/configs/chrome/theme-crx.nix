{pkgs}: {
  id,
  name,
  packageName,
  publicKey,
  version,
  theme,
}: let
  manifestJson = builtins.toJSON {
    manifest_version = 3;
    key = publicKey;
    inherit name version theme;
  };
  package = pkgs.runCommand "${packageName}-chrome-theme" {nativeBuildInputs = [pkgs.google-chrome];} ''
    mkdir -p ext home config cache
    export HOME=$PWD/home XDG_CONFIG_HOME=$PWD/config XDG_CACHE_HOME=$PWD/cache

    cat > ext/manifest.json <<'EOF'
    ${manifestJson}
    EOF

    google-chrome-stable \
      --pack-extension=$PWD/ext \
      --no-message-box \
      --disable-crash-reporter \
      --user-data-dir=$PWD/profile

    mkdir -p $out
    cp ext.crx $out/theme.crx
    cat > $out/update.xml <<EOF
    <?xml version='1.0' encoding='UTF-8'?>
    <gupdate xmlns='http://www.google.com/update2/response' protocol='2.0'>
      <app appid='${id}'>
        <updatecheck codebase='file://$out/theme.crx' version='${version}' />
      </app>
    </gupdate>
    EOF
  '';
in {
  inherit id package version;
  extension = "${id};file://${package}/update.xml";
}
