{pkgs, ...}: let
  steam-capped = pkgs.writeShellScriptBin "steam-capped" ''
    exec /run/current-system/sw/bin/systemd-run --user --scope --collect \
      -p AllowedCPUs=0-19 \
      /run/current-system/sw/bin/steam "$@"
  '';
in {
  home.packages = [steam-capped];

  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Game Client";
    comment = "Application for managing and playing games on Steam";
    exec = "steam-capped %U";
    icon = "steam";
    terminal = false;
    categories = [
      "Network"
      "FileTransfer"
      "Game"
    ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
  };
}
