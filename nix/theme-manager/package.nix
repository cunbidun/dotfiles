{
  lib,
  python3,
  pkgs ? python3.pkgs,
}: let
  # Pull common libs from python's pkgs set's top-level if available
  inherit (pkgs) gobject-introspection gtk3 libappindicator-gtk3 glib pango harfbuzz gdk-pixbuf atk;
in
  python3.pkgs.buildPythonApplication {
    pname = "theme-manager";
    version = "0.1.0";

    src = ./.;
    format = "pyproject";

    nativeBuildInputs = with python3.pkgs; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python3.pkgs;
      [
        pyyaml
        pystray
        pillow
        pygobject3
      ]
      ++ [gobject-introspection gtk3 libappindicator-gtk3 pango harfbuzz gdk-pixbuf atk];

    # Wrap to ensure typelib discovery (Gtk/AppIndicator) at runtime
    makeWrapperArgs = [
      "--set GI_TYPELIB_PATH ${gtk3.out}/lib/girepository-1.0:${gobject-introspection.out}/lib/girepository-1.0:${glib.out}/lib/girepository-1.0:${libappindicator-gtk3.out}/lib/girepository-1.0:${pango.out}/lib/girepository-1.0:${harfbuzz.out}/lib/girepository-1.0:${gdk-pixbuf.out}/lib/girepository-1.0:${atk.out}/lib/girepository-1.0"
      "--set XDG_DATA_DIRS ${gtk3.out}/share:${libappindicator-gtk3.out}/share:$XDG_DATA_DIRS"
      "--set PYSTRAY_BACKEND appindicator"
    ];

    meta = with lib; {
      description = "Daemon & CLI for managing themes";
      license = licenses.mit;
      maintainers = ["cunbidun"];
      platforms = platforms.all;
    };
  }
