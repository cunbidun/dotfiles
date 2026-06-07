{userdata, ...}: {
  sops.secrets.github_read_only_token = {
    sopsFile = ../../../secrets/user.yaml;
    path = "/home/${userdata.username}/.config/opencode/github_read_only_token";
    owner = userdata.username;
    group = "users";
    mode = "0400";
  };
  sops.secrets.ninerouter_api_key = {
    sopsFile = ../../../secrets/user.yaml;
    path = "/home/${userdata.username}/.config/opencode/ninerouter_api_key";
    owner = userdata.username;
    group = "users";
    mode = "0400";
  };
}
