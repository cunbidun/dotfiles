{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  nix = {
    optimise.automatic = true;
    # TODO: this some how break 'nix develop'
    # https://github.com/maralorn/nix-output-monitor/issues/166
    # https://github.com/maralorn/nix-output-monitor/issues/140
    # package = inputs.nix-monitored.packages.${pkgs.system}.default;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = "nix-command flakes pipe-operators";
      accept-flake-config = true;
      builders-use-substitutes = true;
      trusted-users = ["root" "@wheel" "cunbidun"];
      eval-cache = true;
    };
  };
}
