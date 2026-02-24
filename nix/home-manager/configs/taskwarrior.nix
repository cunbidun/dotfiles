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
  '';

  # Keep default Timewarrior config path declarative and pin its data location.
  xdg.configFile."timewarrior/timewarrior.cfg".text = ''
    data.location=${timewarriorDataDir}
  '';

  # Taskwarrior hook: start/stop Timewarrior whenever task start state changes.
  home.file.".local/share/task/hooks/on-modify.timewarrior" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      old_json="$(${pkgs.coreutils}/bin/head -n1)"
      new_json="$(${pkgs.coreutils}/bin/head -n1)"

      # Pass through task JSON no matter what.
      passthrough() {
        printf '%s\n' "$new_json"
      }

      old_uuid="$(${pkgs.jq}/bin/jq -r '.uuid // empty' <<<"$old_json")"
      new_uuid="$(${pkgs.jq}/bin/jq -r '.uuid // empty' <<<"$new_json")"
      old_start="$(${pkgs.jq}/bin/jq -r '.start // empty' <<<"$old_json")"
      new_start="$(${pkgs.jq}/bin/jq -r '.start // empty' <<<"$new_json")"

      # Build a conservative tag set for time tracking.
      project_tag="$(${pkgs.jq}/bin/jq -r '.project // empty' <<<"$new_json")"
      description_tag="$(${pkgs.jq}/bin/jq -r '.description // empty' <<<"$new_json" | ${pkgs.gnused}/bin/sed 's/[^[:alnum:]]\+/_/g' | ${pkgs.coreutils}/bin/cut -c1-40)"

      if [[ -z "$old_start" && -n "$new_start" ]]; then
        tags=("+task")
        [[ -n "$new_uuid" ]] && tags+=("+uuid_''${new_uuid}")
        [[ -n "$project_tag" ]] && tags+=("+project_''${project_tag}")
        [[ -n "$description_tag" ]] && tags+=("+task_''${description_tag}")
        ${pkgs.timewarrior}/bin/timew start :yes "''${tags[@]}" >/dev/null 2>&1 || true
      elif [[ -n "$old_start" && -z "$new_start" ]]; then
        # Stop only the interval that carries this task UUID tag.
        if [[ -n "$old_uuid" ]]; then
          ${pkgs.timewarrior}/bin/timew stop :yes +uuid_"''${old_uuid}" >/dev/null 2>&1 || true
        else
          ${pkgs.timewarrior}/bin/timew stop :yes >/dev/null 2>&1 || true
        fi
      fi

      passthrough
    '';
  };
}
