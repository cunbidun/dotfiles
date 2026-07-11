{
  config,
  pkgs,
  lib,
  ...
}:
let
  images = builtins.fromJSON (builtins.readFile ./container-images.json);
  image = images."9router";
  # Podman (containers/image) rejects `repo:tag@digest` references, so pin by
  # digest only; the tag in container-images.json is informational.
  imageRef = "${image.repository}@${image.digest}";
  dataDir = "${config.home.homeDirectory}/.local/share/9router";
  gptModels = [
    "gpt-6.6-sol"
    "gpt-5.6-sol"
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
  modelAliases = builtins.listToAttrs (
    map (model: {
      name = model;
      value = "cx/${model}";
    }) gptModels
  );
  modelAliasesFile = pkgs.writeText "9router-model-aliases.json" (builtins.toJSON modelAliases);
  settingsFile = pkgs.writeText "9router-settings.json" (
    builtins.toJSON {
      cavemanEnabled = false;
      cavemanLevel = "full";
      ponytailEnabled = false;
    }
  );

  modelAliasesScript = pkgs.writeShellApplication {
    name = "9router-model-aliases";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      pkgs.sqlite
      pkgs.systemd
    ];
    text = ''
      base_url="http://127.0.0.1:20128"
      data_dir="${dataDir}"
      auth_dir="$data_dir/auth"
      db="$data_dir/db/data.sqlite"

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

      if [ -s "$db" ]; then
        before="$(sqlite3 "$db" "select data from settings where id = 1;" || true)"
        sqlite3 "$db" "insert into settings (id, data) values (1, json(readfile('${settingsFile}'))) on conflict(id) do update set data = json_patch(data, json(readfile('${settingsFile}')));"
        after="$(sqlite3 "$db" "select data from settings where id = 1;" || true)"
        if [ "$before" != "$after" ]; then
          systemctl --user restart podman-9router.service
          for _ in $(seq 1 60); do
            if curl -fsS "$base_url/api/health" >/dev/null; then
              break
            fi
            sleep 1
          done
          curl -fsS "$base_url/api/health" >/dev/null
        fi
      fi

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
  };
in
{
  services.podman = {
    enable = true;
    containers."9router" = {
      image = imageRef;
      autoStart = true;
      # The app runs as uid/gid 1000 inside the container; map the host user
      # onto it so files in dataDir stay owned by the user instead of a
      # subuid (which would lock the user out of their own data). keep-id
      # defaults the run user to the mapped uid, but the entrypoint must
      # start as container root: it uses su-exec to drop to 1000 itself.
      userNS = "keep-id:uid=1000,gid=1000";
      user = "0";
      group = "0";
      ports = [ "20128:20128" ];
      volumes = [ "${dataDir}:/app/data" ];
      environment = {
        DATA_DIR = "/app/data";
      };
    };
  };

  home.activation."9routerDataDir" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -d -m 0750 ${lib.escapeShellArg dataDir}
    run install -d -m 0700 ${lib.escapeShellArg "${dataDir}/auth"}
  '';

  systemd.user.services."9router-model-aliases" = {
    Unit = {
      Description = "Reconcile declarative 9router model aliases";
      After = [ "podman-9router.service" ];
      Wants = [ "podman-9router.service" ];
    };
    Service = {
      Type = "oneshot";
      # Stay "active" after completion so sd-switch re-runs the service when
      # the alias set (embedded via the script path) changes.
      RemainAfterExit = true;
      ExecStart = "${modelAliasesScript}/bin/9router-model-aliases";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
