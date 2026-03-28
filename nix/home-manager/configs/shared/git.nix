{userdata, ...}: {
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user = {
        name = userdata.name;
        email = userdata.email;
      };
    };
  };
}
