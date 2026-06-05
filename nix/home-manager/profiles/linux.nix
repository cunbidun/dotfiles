{ userdata, ... }: {
  home.username = userdata.username;
  home.homeDirectory = "/home/${userdata.username}";
  programs.home-manager.enable = true;
  programs.atuin.enable = true;
}
