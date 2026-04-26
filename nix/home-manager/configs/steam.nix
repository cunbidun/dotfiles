{pkgs, ...}: let
  steam-capped = pkgs.writeShellScriptBin "steam-capped" ''
    last_cpu=$(( $(nproc) - 1 ))
    systemctl --user set-property steam.slice AllowedCPUs=1-''${last_cpu}
    exec /run/current-system/sw/bin/systemd-run --user \
      --slice=steam.slice --scope --collect \
      /run/current-system/sw/bin/steam "$@"
  '';
in {
  home.packages = [steam-capped];

  systemd.user.slices.steam = {
    Unit.Description = "Steam slice (CPU-capped)";
  };

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
