# Shared DNS resolver setup for ad-blocking services.
{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = ["127.0.0.1" "::1"];
        port = 5335;
        prefetch = true;
        access-control = [
          "127.0.0.0/8 allow"
        ];
      };
    };
  };

  services.resolved.enable = false;
}
