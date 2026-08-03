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
    ./9router-home.nix
    ../../home-manager/profiles/linux.nix
    inputs.sops-nix.homeManagerModules.sops
    ../../home-manager/configs/zsh.nix
    ../../home-manager/configs/direnv.nix
    ../../home-manager/configs/starship.nix
    ../../home-manager/configs/tmux
    ../../home-manager/configs/nvim.nix
    ../../home-manager/configs/shared/git.nix
    ../../home-manager/configs/llm_agent.nix
    ../../home-manager/configs/user-secrets.nix
    ../../home-manager/configs/yazi.nix
    ../../home-manager/configs/clipboard-bridge
    ../../home-manager/configs/activitywatch/server.nix
  ];

  # Only include default packages, no GUI packages
  home.packages = package_config.default_packages;

  # Headless host: Claude Code here reads screenshots from whichever desktop
  # machine the SSH session came from (see configs/clipboard-bridge).
  services.clipboardBridge.sink = {
    enable = true;
    x11 = {
      # Codex reads the clipboard in-process (via the arboard crate) instead of
      # shelling out, so the xclip/wl-paste shims never intercept it and Ctrl+V
      # fails with an X11 connection error. A headless X server whose CLIPBOARD
      # selection we own fixes that.
      enable = true;
      # Wrap codex alone rather than exporting DISPLAY for the session: this host
      # has no display, and advertising one globally would make every other tool
      # believe a GUI exists.
      wrapPrograms = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
      ];
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
  };

  home.stateVersion = "25.05";

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "opencode web interface";
      After = ["network.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
      }/bin/opencode web --port 10300 --hostname 0.0.0.0";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
