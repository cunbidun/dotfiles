{
  lib,
  config,
  pkgs,
  inputs,
  userdata,
  ...
}: let
  inherit (pkgs.stdenv) isLinux isDarwin;
in {
  services.vicinae = {
    enable = true;
    autoStart = true;
    settings = {
      faviconService = "twenty"; # twenty | google | none
      font.size = 11;
      popToRootOnClose = false;
      rootSearch.searchFiles = false;
      window = {
        csd = true;
        opacity = 0.95;
        rounding = 0;
      };
    };
  };

  systemd.user.services.vicinae = {
    Unit = {
      X-Restart-Triggers = ["%h/.config/vicinae/vicinae.json"];
    };
  };
}
