{ pkgs, lib, ... }:
{
  nix = {
    optimise.automatic = true;
    # TODO: this some how break 'nix develop'
    # https://github.com/maralorn/nix-output-monitor/issues/166
    # https://github.com/maralorn/nix-output-monitor/issues/140
    # package = inputs.nix-monitored.packages.${pkgs.stdenv.hostPlatform.system}.default;
    gc = {
      automatic = true;
      # Darwin uses launchd calendar intervals; NixOS uses systemd OnCalendar strings
      interval = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { Weekday = 6; Hour = 9; Minute = 0; };
      dates = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) "Sat 09:00";
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = "nix-command flakes";
      accept-flake-config = true;
      builders-use-substitutes = true;
      trusted-users = [
        "root"
        "@wheel"
        "cunbidun"
      ];
      eval-cache = true;
    };
  };
}
