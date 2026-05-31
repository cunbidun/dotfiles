{ ... }: {
  services.nginx = {
    enable = true;
    virtualHosts."home-page" = {
      root = "/srv/home-page";
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [80];
}
