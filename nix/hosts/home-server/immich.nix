{ ... }:
{
  services.immich = {
    enable = true;
    mediaLocation = "/srv/storage/immich";
    # tailscale serve proxies to 127.0.0.1; "localhost" resolves to ::1 here
    host = "127.0.0.1";
  };
}
