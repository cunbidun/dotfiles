{
  lib,
  pkgs,
  ...
}: let
  images = builtins.fromJSON (builtins.readFile ./container-images.json);
  image = images."9router";
  gptModels = [
    "gpt-5.5"
    "gpt-5.5-review"
    "gpt-5.4"
    "gpt-5.4-review"
    "gpt-5.4-mini"
    "gpt-5.4-mini-review"
    "gpt-5.3-codex"
    "gpt-5.3-codex-review"
    "gpt-5.3-codex-xhigh"
    "gpt-5.3-codex-xhigh-review"
    "gpt-5.3-codex-high"
    "gpt-5.3-codex-high-review"
    "gpt-5.3-codex-low"
    "gpt-5.3-codex-low-review"
    "gpt-5.3-codex-none"
    "gpt-5.3-codex-none-review"
    "gpt-5.3-codex-spark"
    "gpt-5.3-codex-spark-review"
  ];
  modelAliases = builtins.listToAttrs (map (model: {
      name = model;
      value = "cx/${model}";
    })
    gptModels);
  modelAliasesFile = pkgs.writeText "9router-model-aliases.json" (builtins.toJSON modelAliases);
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/9router 0750 root root -"
    "d /var/lib/9router/auth 0700 root root -"
  ];

  systemd.services."9router-model-aliases" = {
    description = "Reconcile declarative 9router model aliases";
    after = [
      "docker-9router.service"
      "network-online.target"
    ];
    wants = [
      "docker-9router.service"
      "network-online.target"
    ];
    wantedBy = ["multi-user.target"];
    restartTriggers = [modelAliasesFile];

    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];

    script = ''
      set -euo pipefail

      base_url="http://127.0.0.1:20128"
      data_dir="/var/lib/9router"
      auth_dir="$data_dir/auth"

      install -d -m 0750 "$data_dir"
      install -d -m 0700 "$auth_dir"

      if [ ! -s "$data_dir/machine-id" ]; then
        od -An -N16 -tx1 /dev/urandom | tr -d ' \n' > "$data_dir/machine-id"
        chmod 0600 "$data_dir/machine-id"
      fi

      if [ ! -s "$auth_dir/cli-secret" ]; then
        od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "$auth_dir/cli-secret"
        chmod 0600 "$auth_dir/cli-secret"
      fi

      for _ in $(seq 1 60); do
        if curl -fsS "$base_url/api/health" >/dev/null; then
          break
        fi
        sleep 1
      done

      curl -fsS "$base_url/api/health" >/dev/null

      raw_id="$(tr -d '\r\n' < "$data_dir/machine-id")"
      cli_secret="$(tr -d '\r\n' < "$auth_dir/cli-secret")"
      cli_token="$(printf '%s' "$raw_id"'9r-cli-auth'"$cli_secret" | sha256sum | cut -c1-16)"

      jq -r 'to_entries[] | [.key, .value] | @tsv' ${modelAliasesFile} | while IFS=$'\t' read -r alias model; do
        payload="$(jq -n --arg alias "$alias" --arg model "$model" '{alias: $alias, model: $model}')"
        curl -fsS -X PUT \
          -H "x-9r-cli-token: $cli_token" \
          -H "Content-Type: application/json" \
          -d "$payload" \
          "$base_url/api/models/alias" >/dev/null
      done
    '';

    serviceConfig = {
      Type = "oneshot";
    };
  };

  system.activationScripts."9router-model-aliases" = lib.stringAfter ["specialfs"] ''
    if [ -z "''${NIXOS_ACTION:-}" ] || [ "''${NIXOS_ACTION:-}" = switch ]; then
      ${pkgs.systemd}/bin/systemctl start 9router-model-aliases.service || true
    fi
  '';

  networking.firewall.allowedTCPPorts = [20128];

  virtualisation.oci-containers = {
    backend = "docker";
    containers."9router" = {
      image = "${image.repository}:${image.tag}@${image.digest}";
      # The service is restarted when the pinned digest changes. Pull on start so
      # Docker resolves the new manifest to the current platform image instead
      # of reusing an older cached digest for the tag.
      pull = "always";
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
