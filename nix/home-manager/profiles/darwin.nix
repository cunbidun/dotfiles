{ userdata, ... }: {
  home.username = userdata.username;
  home.homeDirectory = "/Users/${userdata.username}";
  programs.home-manager.enable = true;
  programs.atuin.enable = true;
}
