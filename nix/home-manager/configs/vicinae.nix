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

  systemd.user.services.vicinae-reload = {
    Unit = {
      Description = "Restart Vicinae after config updates";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart vicinae.service";
    };
  };

  systemd.user.paths.vicinae-reload = {
    Unit = {
      Description = "Watch Vicinae config for changes";
    };
    Path = {
      PathModified = "%h/.config/vicinae/vicinae.json";
      PathChanged = "%h/.config/vicinae";
      Unit = "vicinae-reload.service";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
