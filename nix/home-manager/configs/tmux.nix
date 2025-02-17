{
  pkgs,
  lib,
  ...
}: let
  # Helper function to fetch a vim plugin from GitHub.
  customTmuxPlugin = {
    owner,
    repo,
    rev,
    sha256,
    pname,
  }:
    pkgs.stdenv.mkDerivation {
      pname = pname;
      name = pname + "-" + rev;
      src = pkgs.fetchFromGitHub {
        owner = owner;
        repo = repo;
        rev = rev;
        sha256 = sha256;
      };
      installPhase = ''
        mkdir -p $out
        cp -r . $out
      '';
    };

  extrakto = customTmuxPlugin {
    owner = "laktak";
    repo = "extrakto";
    rev = "master";
    sha256 = "sha256-pzinDE6zRne470Hid5Y53e5ZmUjieCsD/6xghBO3898=";
    pname = "extrakto";
  };

  # tmux-easy-motion = customTmuxPlugin {
  #   owner = "IngoMeyer441";
  #   repo = "tmux-easy-motion";
  #   rev = "master";
  #   sha256 = "sha256-wOIPq12OqqxLERKfvVp4JgLkDXnM0KKtTqRWMqj4rfs=";
  #   pname = "tmux-easy-motion";
  # };

  tmux-plugin-list = [
    extrakto
  ];

  local-plugin-dir = pkgs.runCommand "vim-plugins" {} ''
    mkdir -p $out

    # Regular plugins
    ${lib.concatMapStrings (plugin: ''
        ln -s "${plugin}" "$out/${plugin.pname}"
      '')
      tmux-plugin-list}

  '';
in {
  home.file.".local/share/tmux-plugins".source = local-plugin-dir;
}
