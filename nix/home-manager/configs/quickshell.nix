{inputs, pkgs, lib, ...}: let
  system = pkgs.stdenv.hostPlatform.system;
  qsPkgs = import inputs.quickshell.inputs.nixpkgs {inherit system;};
  qsWrapper = qsPkgs.stdenv.mkDerivation {
    name = "illogical-impulse-quickshell-wrapper";
    meta = with qsPkgs.lib; {
      description = "Quickshell bundled Qt deps for home-manager usage";
      license = licenses.gpl3Only;
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
      qsPkgs.makeWrapper
      qsPkgs.qt6.wrapQtAppsHook
    ];

    buildInputs = with qsPkgs; [
      inputs.quickshell.packages.${system}.default
      kdePackages.qtwayland
      kdePackages.qtpositioning
      kdePackages.qtlocation
      kdePackages.syntax-highlighting
      gsettings-desktop-schemas
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qt5compat
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qttranslations
      qt6.qtvirtualkeyboard
      qt6.qtwayland
      kdePackages.kirigami
      kdePackages.kdialog
      kdePackages.syntax-highlighting
    ];

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${inputs.quickshell.packages.${system}.default}/bin/qs $out/bin/qs \
          --prefix XDG_DATA_DIRS : ${qsPkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${qsPkgs.gsettings-desktop-schemas.name}
      chmod +x $out/bin/qs
    '';
  };

  qsBin = "${qsWrapper}/bin/qs";

  configOverrides = {
    panelFamily = "ii";
    overview = {
      enable = true;
    };
    dock = {
      enable = false;
    };
    sidebar = {
      keepRightSidebarLoaded = false;
      cornerOpen = {
        enable = false;
      };
    };
    bar = {
      autoHide = {
        enable = true;
        pushWindows = false;
        showWhenPressingSuper = {
          enable = false;
          delay = 0;
        };
      };
    };
  };

  unitSection = {
    After = ["graphical-session.target"];
  };
  installSection = {
    WantedBy = ["graphical-session.target"];
  };
in {
  home.packages = [qsWrapper];

  xdg.configFile."quickshell/ii" = {
    source = "${inputs.dots-hyprland}/dots/.config/quickshell/ii";
    recursive = true;
  };

  xdg.configFile."illogical-impulse/config.json".text = builtins.toJSON configOverrides;

  systemd.user.services.quickshell = {
    Unit = unitSection;
    Service = {
      Type = "simple";
      WorkingDirectory = "%h";
      ExecStart = "${qsBin} -c ii";
      ExecStartPost = "${pkgs.bash}/bin/bash -lc '${pkgs.coreutils}/bin/sleep 1; ${qsBin} -c ii ipc call bar close'";
      Restart = "on-failure";
      StandardOutput = "journal";
      StandardError = "journal";
      Slice = ["app-graphical.slice"];
    };
    Install = installSection;
  };
}
