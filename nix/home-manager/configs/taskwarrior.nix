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
