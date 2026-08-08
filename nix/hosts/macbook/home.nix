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
    ../../home-manager/configs/llm_agent.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/user-secrets.nix
    ../../home-manager/configs/clipboard-bridge
    ../../home-manager/configs/activitywatch/darwin.nix
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

  # Keep one dedicated reverse tunnel to home-server rather than attaching it to
  # interactive sessions: only the first session can bind the port, so with
  # several open the others silently lose the tunnel and paste breaks depending
  # on which session is oldest.
  services.clipboardBridge.source.tunnelTo = ["home-server"];

  # The daemon role here is filled by upstream clipaste (installed outside Nix),
  # which already serves the same HTTP contract on 127.0.0.1:18340 and reads the
  # macOS pasteboard natively. Enabling our own source would collide on that
  # port, so only the tunnel below is configured on this host; the module's
  # source role is used on the nixos desktop, where clipaste refuses to run.
  services.clipboardBridge.source.enable = false;

  # SSH client config, declarative (mirrors nix/hosts/nixos/home.nix). The
  # clipboard tunnel deliberately lives in its own connection above rather than
  # in this block, so opening several sessions cannot break it.
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
      };
    };
  };
  home.activation.setDefaultBrowser = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure Chrome is the default handler for HTTP/HTTPS
    ${pkgs.mac-default-browser}/bin/default-browser --identifier com.google.chrome
  '';
}
