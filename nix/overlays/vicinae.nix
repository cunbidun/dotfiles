inputs: final: prev: {
  vicinae = prev.stdenv.mkDerivation rec {
    pname = "vicinae";
    version = "0.2.1";

    src = inputs.vicinae;

    nativeBuildInputs = with prev; [autoPatchelfHook qt6.wrapQtAppsHook];
    buildInputs = with prev; [
      qt6.qtbase
      qt6.qtsvg
      qt6.qttools
      qt6.qtwayland
      qt6.qtdeclarative
      qt6.qt5compat
      kdePackages.qtkeychain
      kdePackages.layer-shell-qt
      openssl
      cmark-gfm
      libqalculate
      minizip
      stdenv.cc.cc.lib
      abseil-cpp
      protobuf
      nodejs
      wayland
    ];

    # No unpackPhase needed since src is already extracted by Nix

    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      cp bin/vicinae $out/bin/
      cp share/applications/vicinae.desktop $out/share/applications/
      chmod +x $out/bin/vicinae
    '';

    dontWrapQtApps = true;

    preFixup = ''
      wrapQtApp "$out/bin/vicinae" --prefix LD_LIBRARY_PATH : ${prev.lib.makeLibraryPath buildInputs}
    '';

    meta = with prev.lib; {
      description = "A focused launcher for your desktop — native, fast, extensible";
      homepage = "https://github.com/vicinaehq/vicinae";
      license = licenses.gpl3;
      maintainers = [];
      platforms = platforms.linux;
    };
  };
}
