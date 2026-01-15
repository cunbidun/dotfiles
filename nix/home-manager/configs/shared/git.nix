{userdata, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userdata.name;
        email = userdata.email;
      };
    };
  };
}
