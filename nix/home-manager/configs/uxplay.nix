{
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.uxplay = {
    Unit = {
      Description = "UxPlay AirPlay Server";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.uxplay}/bin/uxplay -p";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
