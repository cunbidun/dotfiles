{pkgs}: {
  id,
  name,
  packageName,
  version,
  theme,
}: let
  manifestJson = builtins.toJSON {
    manifest_version = 3;
    inherit name version theme;
  };
  # Throwaway CRX key. This is package identity only, not a user/account secret.
  privateKey = pkgs.writeText "theme-manager-chrome-theme.pem" ''
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5oM9ezsjd1l75
    nmhZ26Ue190Q06A6xx3SYfwbcpOGqeBtT3R8/UXP2q7M+vzs6t5cDksGFU+Ifu+V
    /Uoo21dPmI5x492+C1UhJeFhZd8qWOz96kV4tegXK7hmw+9O1A9d6RPJ0ZhoXpxb
    STpDVtE7jJLOQpZyr0VvZEv8WydUln3DUPwh+bmvlyeZwmHn0r+RlvC0eA1wkVKw
    8JS7qVGvIbFjXC3eMSg5BktLr7UR0Hau4JaiNT6WGF1c7eqKqFDTJzcbbCZLfCpg
    aDj/2yv/hZtiRApa9VeceS7MoD8KyVrd2qvUEPJzd76f/IZrwuUuSsKObwcYjCHF
    MWWSjlLpAgMBAAECggEAD8sm2aIuZPGAUyyvJDYT7nPfUzcuQtH+L5A2qv8sniCF
    /8bq2leSQQUSKk6QhnfVQ2/T4kid47cpG1HZpXBEFXmdZQNGMo00SQW4D1lji27V
    eyUblBGmFZKateOl0McqJ4tVK66xkO+7zeiFFIWmd7KWKwZvVoKjHb8i1+3JguDF
    sfawOXuBcav8yxUUXBiGY5H3+oGgoCPau3yuSP8Y3s1VgE+FYG3ZgO5p37E2k1NX
    uquw0L7bVsyzFCijGByP3VegxvqasV8rlLFqyXukyOo4wygaLtTlU39aCXxgy1g3
    PYqivD1D2oJgS0BpA5hZDDdkO4ck22+IDNnruDh1oQKBgQDzCrBaCPfpBxI1w45+
    s77yC7PQLokuKeZWfZRx7aptVfbLT5xtkG6SgwUfuiQk2gCaX30VoHEHZOzRp4D2
    UDR8ZWPwJkceWBR1WlKpCl4f8Q7S/RxFS/gXO7TUv9oOfk2Y5+GS0vPfVMznG3ib
    k4yF2iJJZSxHX587aMJ5kMxfZwKBgQDDhnmZpGfJcS07tFN/+0pqKsiE9GnFHg99
    hDC27bPhI6A7w3MYFoTKqA0pc6cwg8CpWSYBuLDt14zKecEY7Dxezx4VcAfwQwVp
    62j17pUAGA8hZjevb/7lo8QZAFvwSTko55AKXU2Nb+tbHaRpAgVPU2dCTRmYTdfN
    6zfNbHJZLwKBgQDf4Fu8RAChThsvHTlYaxib+72iKgvBU2VTDJC+NXBFEOeqNmZg
    4qeIHFqO9DcxHwNpMEaXslgLuKMRKNv5iL4gTIE3iPr/76DAzPfRsLQtdi7ymab+
    ClG4jQ4w35zsttmh3Q+D4QA2G/Y3eK2rmcnazqnAtAqKoIGcBw8FTiWERwKBgC5P
    1M+ajGa/YupoXPrMZ6Tb+2Daj477/slJHUzG4rtp99MQCVvkQZHK2ks+NJSeMG0s
    S39O4sGDM7rlueIQWoBOaJ7FSWwUQ90BwHu4Bhzelf7gOkJYsbRs5M7TMfOpNFvG
    9WwvC2Z74vBTBhVFQEK4y5V9s5lKntoMY8xJapBLAoGAbE+MHQGtiThC4My6WlQu
    pJFvK3POUK3Tw/+cWNp3qicF2k/Wj5NZZlGEMETMnsR+lKqc36wza6f4OHunpiUq
    jS115clxeWVNKdBbUy5SLdYyfBArABZwUuxCB35GTnDKeBQedVLmjMOSO3hlUV8o
    LnrN9jI60Acrzh96Wk7uKdU=
    -----END PRIVATE KEY-----
  '';
  package = pkgs.runCommand "${packageName}-chrome-theme" {nativeBuildInputs = [pkgs.google-chrome];} ''
    mkdir -p ext home config cache
    export HOME=$PWD/home XDG_CONFIG_HOME=$PWD/config XDG_CACHE_HOME=$PWD/cache

    cat > ext/manifest.json <<'EOF'
    ${manifestJson}
    EOF

    google-chrome-stable \
      --pack-extension=$PWD/ext \
      --pack-extension-key=${privateKey} \
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
