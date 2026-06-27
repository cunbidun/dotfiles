{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  pokemonExtensionId = "a2cd0c72-8b73-4610-b0d9-f838a519fccf";
in {
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    # Use vicinae's own package from its flake to match the cache
    package = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # Hyprland 0.52 started validating exclusive edge anchors and
    # LayerShellQt (used by Vicinae) currently violates that contract,
    # so disable layer shell until upstream fixes the issue.
  };

  systemd.user.services.vicinae = {
    Unit.X-SwitchMethod = "keep-old";
    Service.KillMode = lib.mkForce "control-group";
  };

  home.file = {
    ".local/share/vicinae/themes/theme-manager-default-light.toml".source = ./default-light.toml;
    ".local/share/vicinae/themes/theme-manager-default-dark.toml".source = ./default-dark.toml;
  };

  home.activation = lib.mkIf config.services.vicinae.enable {
    removePokemonExtension = lib.hm.dag.entryAfter ["writeBoundary"] ''
      rm -rf "$HOME/.local/share/vicinae/extensions/${pokemonExtensionId}"
    '';
  };

  # GLib terminal handler must use kitty -e, not kitty +open, or Vicinae shows "Unknown URL type"
  dconf.settings."org/gnome/desktop/default-applications/terminal" = {
    exec = "kitty";
    exec-arg = "-e";
  };
}
