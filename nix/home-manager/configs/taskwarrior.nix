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
    # Set this to the same secret on every replica:
    # sync.encryption_secret=REPLACE_ME
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
}
