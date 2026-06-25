{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  pokemonExtensionId = "a2cd0c72-8b73-4610-b0d9-f838a519fccf";
in
{
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
    settings = {
      faviconService = "twenty"; # twenty | google | none
      font.size = 11;
      popToRootOnClose = false;
      rootSearch.searchFiles = false;
      window = {
        csd = true;
        opacity = 0.95;
        rounding = 0;
      };
    };
  };

  systemd.user.services.vicinae.Unit.X-SwitchMethod = "keep-old";

  home.activation = lib.mkIf config.services.vicinae.enable {
    applyVicinaeTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      vicinae_config="$HOME/.config/vicinae/vicinae.json"
      vicinae_theme=""
      if [ -r "$vicinae_config" ]; then
        vicinae_theme="$(${pkgs.jq}/bin/jq -r '.theme.name // empty' "$vicinae_config")"
      fi
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "$vicinae_theme" ] && ${pkgs.systemd}/bin/systemctl --user is-active --quiet vicinae.service; then
        "$newGenPath/home-path/bin/vicinae" theme set "$vicinae_theme" >/dev/null
      fi
    '';

    removePokemonExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf "$HOME/.local/share/vicinae/extensions/${pokemonExtensionId}"
    '';
  };

  # GLib terminal handler must use kitty -e, not kitty +open, or Vicinae shows "Unknown URL type"
  dconf.settings."org/gnome/desktop/default-applications/terminal" = {
    exec = "kitty";
    exec-arg = "-e";
  };
}
