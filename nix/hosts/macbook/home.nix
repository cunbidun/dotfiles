{
  pkgs,
  config,
  lib,
  inputs,
  userdata,
  ...
}: let
  package_config = import ../../home-manager/packages.nix {
    pkgs = pkgs;
    inputs = inputs;
  };
in {
  imports = [
    ../../home-manager/profiles/darwin.nix
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/tmux
    ../../home-manager/configs/vscode.nix
    ../../home-manager/configs/llm_agent.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/user-secrets.nix
    ../../home-manager/configs/clipboard-bridge
    inputs.self.homeManagerModules.theme-manager
    inputs.mac-app-util.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
  ];
  home.packages = package_config.default_packages ++ package_config.mac_packages;
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "iterm2";
  };

  home.file = {
    ".config/iterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/utilities/iterm";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userdata.name;
        email = userdata.email;
      };
    };
  };

  # Screenshots taken on this Mac are readable from SSH sessions it opens.
  services.clipboardBridge.source.enable = true;

  # SSH client config, declarative (mirrors nix/hosts/nixos/home.nix). The
  # RemoteForward on `home-server` is the clipboard-bridge reverse tunnel: it
  # exposes this Mac's daemon as a unix socket on the server, where the
  # xclip/wl-paste shims read it. Paste with Ctrl+V in Claude Code over SSH.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
        ForwardAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
        # Quotes are part of the value: the path contains spaces.
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
      "home-server" = {
        HostName = "home-server";
        RemoteForward = "${config.services.clipboardBridge.socketPath} 127.0.0.1:${toString config.services.clipboardBridge.source.port}";
      };
    };
  };
  home.activation.setDefaultBrowser = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure Chrome is the default handler for HTTP/HTTPS
    ${pkgs.mac-default-browser}/bin/default-browser --identifier com.google.chrome
  '';
}
