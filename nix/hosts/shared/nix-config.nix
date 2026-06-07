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
      options = "--delete-older-than 30d";
    } // (if pkgs.stdenv.hostPlatform.isDarwin then {
      # macOS: launchd StartCalendarInterval format
      interval = { Weekday = 6; Hour = 9; Minute = 0; };
    } else {
      # NixOS: systemd OnCalendar format
      dates = "Sat 09:00";
    });
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
