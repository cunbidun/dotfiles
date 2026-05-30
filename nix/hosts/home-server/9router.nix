{
  ...
}: let
  images = builtins.fromJSON (builtins.readFile ./container-images.json);
  image = images."9router";
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/9router 0750 root root -"
  ];

  networking.firewall.allowedTCPPorts = [20128];

  virtualisation.oci-containers = {
    backend = "docker";
    containers."9router" = {
      image = "${image.repository}:${image.tag}@${image.digest}";
      pull = "missing";
      ports = [
        "20128:20128"
      ];
      volumes = [
        "/var/lib/9router:/app/data"
      ];
      environment = {
        DATA_DIR = "/app/data";
      };
    };
  };

  virtualisation.docker.enableOnBoot = true;
}
