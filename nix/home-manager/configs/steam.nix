{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = [pkgs.adwsteamgtk];
  home.activation = let
    applySteamTheme = pkgs.writeShellScript "applySteamTheme" ''
      # This file gets copied with read-only permission from the nix store
      # if it is present, we need to make it writable before running the installer
      custom="$HOME/.cache/AdwSteamInstaller/extracted/custom/custom.css"
      if [[ -f "$custom" ]]; then
        chmod +w "$custom"
      fi
      ${lib.getExe pkgs.adwsteamgtk} -i
    '';
  in {
    updateSteamTheme = config.lib.dag.entryAfter ["writeBoundary" "dconfSettings"] ''
      run ${applySteamTheme}
    '';
  };

  dconf.settings."io/github/Foldex/AdwSteamGtk".prefs-install-custom-css = true;

  xdg.configFile."AdwSteamGtk/custom.css".text = with config.lib.stylix.colors; ''
    :root
    {
      /* The main accent color and the matching text value */
      --adw-accent-bg-rbg: ${base0D-rgb-r}, ${base0D-rgb-g}, ${base0D-rgb-b};
      --adw-accent-fg-rbg: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-accent-rgb: ${base0D-rgb-r}, ${base0D-rgb-g}, ${base0D-rgb-b};

      /* destructive-action buttons */
      --adw-destructive-bg-rgb: ${base08-rgb-r}, ${base08-rgb-g}, ${base08-rgb-b};
      --adw-destructive-fg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-destructive-rgb: ${base08-rgb-r}, ${base08-rgb-g}, ${base08-rgb-b};

      /* Levelbars, entries, labels and infobars. These don't need text colors */
      --adw-success-bg-rgb: ${base0B-rgb-r}, ${base0B-rgb-g}, ${base0B-rgb-b};
      --adw-success-fg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-success-rgb: ${base0B-rgb-r}, ${base0B-rgb-g}, ${base0B-rgb-b};

      --adw-warning-bg-rgb: ${base0E-rgb-r}, ${base0E-rgb-g}, ${base0E-rgb-b};
      --adw-warning-fg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-warning-fg-a: 0.8;
      --adw-warning-rgb: ${base0E-rgb-r}, ${base0E-rgb-g}, ${base0E-rgb-b};

      --adw-error-bg-rgb: ${base08-rgb-r}, ${base08-rgb-g}, ${base08-rgb-b};
      --adw-error-fg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-error-rgb: ${base08-rgb-r}, ${base08-rgb-g}, ${base08-rgb-b};

      /* Window */
      --adw-window-bg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-window-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};

      /* Views - e.g. text view or tree view */
      --adw-view-bg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-view-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};

      /* Header bar, search bar, tab bar */
      --adw-headerbar-bg-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-headerbar-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};
      --adw-headerbar-border-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-headerbar-backdrop-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-headerbar-shade-rgb: 0, 0, 0;
      --adw-headerbar-shade-a: 0.9;

      /* Split pane views */
      --adw-sidebar-bg-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-sidebar-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};
      --adw-sidebar-backdrop-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-sidebar-shade-rgb: 0, 0, 0;
      --adw-sidebar-shade-a: 0.36;

      --adw-secondary-sidebar-bg-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-secondary-sidebar-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};
      --adw-secondary-sidebar-backdrop-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-secondary-sidebar-shade-rgb: 0, 0, 0;
      --adw-secondary-sidebar-shade-a: 0.36;

      /* Cards, boxed lists */
      --adw-card-bg-rgb: 0, 0, 0;
      --adw-card-bg-a: 0.08;
      --adw-card-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};
      --adw-card-shade-rgb: 0, 0, 0;
      --adw-card-shade-a: 0.36;

      /* Dialogs */
      --adw-dialog-bg-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-dialog-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};

      /* Popovers */
      --adw-popover-bg-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-popover-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};
      --adw-popover-shade-rgb: ${base01-rgb-r}, ${base01-rgb-g}, ${base01-rgb-b};
      --adw-popover-shade-a: 0.36;

      /* Thumbnails */
      --adw-thumbnail-bg-rgb: ${base00-rgb-r}, ${base00-rgb-g}, ${base00-rgb-b};
      --adw-thumbnail-fg-rgb: ${base05-rgb-r}, ${base05-rgb-g}, ${base05-rgb-b};

      /* Miscellaneous */
      --adw-shade-rgb: 0, 0, 0;
      --adw-shade-a: 0.36;
      }
  '';
}
