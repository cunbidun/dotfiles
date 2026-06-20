{ config, ... }:
let
  configHome = config.xdg.configHome;
in
{
  sops = {
    defaultSopsFile = ../../../secrets/user.yaml;
    age.keyFile = "${configHome}/sops/age/keys.txt";

    secrets.github_read_only_token = {
      path = "${configHome}/opencode/github_read_only_token";
      mode = "0400";
    };

    secrets.ninerouter_api_key = {
      path = "${configHome}/opencode/ninerouter_api_key";
      mode = "0400";
    };

    secrets.hyprpanel_weather_api_key = {
      path = "${configHome}/hyprpanel/weather_api_key";
      mode = "0400";
    };
  };
}
