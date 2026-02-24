{
  config,
  pkgs,
  userdata,
  ...
}: let
  taskDataDir = "/home/${userdata.username}/.local/share/task";
  timewarriorDataDir = "/home/${userdata.username}/.local/share/timewarrior";
in {
  home.packages = with pkgs; [
    taskwarrior3
    timewarrior
    python3
  ];

  home.sessionVariables = {
    TASKRC = "${config.xdg.configHome}/task/taskrc";
    TASKDATA = taskDataDir;
    TIMEWARRIORDB = timewarriorDataDir;
  };

  xdg.configFile."task/taskrc".text = ''
    data.location=${taskDataDir}
    hooks=1
    confirmation=1
    verbose=new-id,affected,edit,special,unwait
    recurrence=1

    # TaskChampion sync server
    sync.server.url=http://home-server.${userdata.tailnetDomain}:10222
    sync.server.client_id=9f4cf274-651d-4c8b-a6b7-1a8ddf4af7bc
    # Required by Taskwarrior server sync; plaintext here by design for trusted env.
    sync.encryption_secret=trusted-tailnet-sync-secret
  '';

  # Keep default Timewarrior config path declarative and pin its data location.
  xdg.configFile."timewarrior/timewarrior.cfg".text = ''
    data.location=${timewarriorDataDir}
  '';

  # Official upstream Taskwarrior hook shipped by Timewarrior docs.
  home.file.".local/share/task/hooks/on-modify.timewarrior" = {
    executable = true;
    source = "${pkgs.timewarrior}/share/doc/timew/ext/on-modify.timewarrior";
  };

  # Auto-sync after each task edit (add/modify/start/stop/done/delete).
  home.file.".local/share/task/hooks/on-add.sync" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Hook protocol: on-add receives only the new task JSON.
      new_json="$(${pkgs.coreutils}/bin/head -n1)"
      printf '%s\n' "$new_json"

      # Avoid recursive hook invocations and keep edits snappy.
      if [[ "''${TASK_AUTOSYNC_HOOK:-0}" = "1" ]]; then
        exit 0
      fi

      (
        export TASK_AUTOSYNC_HOOK=1
        export TASKRC="${config.xdg.configHome}/task/taskrc"
        export TASKDATA="${taskDataDir}"
        ${pkgs.coreutils}/bin/mkdir -p "${config.xdg.stateHome}"
        ${pkgs.taskwarrior3}/bin/task rc.hooks=0 rc.verbose=nothing sync \
          >>"${config.xdg.stateHome}/task-autosync.log" 2>&1
      ) &
    '';
  };

  home.file.".local/share/task/hooks/on-modify.sync" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Hook protocol: first line is "old", second line is "new".
      old_json="$(${pkgs.coreutils}/bin/head -n1)"
      new_json="$(${pkgs.coreutils}/bin/head -n1)"

      # Always pass the new task object through.
      printf '%s\n' "$new_json"

      # Avoid recursive hook invocations and keep edits snappy.
      if [[ "''${TASK_AUTOSYNC_HOOK:-0}" = "1" ]]; then
        exit 0
      fi

      (
        export TASK_AUTOSYNC_HOOK=1
        export TASKRC="${config.xdg.configHome}/task/taskrc"
        export TASKDATA="${taskDataDir}"
        ${pkgs.coreutils}/bin/mkdir -p "${config.xdg.stateHome}"
        ${pkgs.taskwarrior3}/bin/task rc.hooks=0 rc.verbose=nothing sync \
          >>"${config.xdg.stateHome}/task-autosync.log" 2>&1
      ) &
    '';
  };
}
