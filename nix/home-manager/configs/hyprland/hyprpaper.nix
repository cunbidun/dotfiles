{
  lib,
  pkgs,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
    };
  };

  systemd.user.services.hyprpaper.Unit.X-SwitchMethod = "keep-old";

  home.activation.applyHyprpaperTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
    hyprpaper_config="$HOME/.config/hypr/hyprpaper.conf"
    wallpaper=""
    if [ -r "$hyprpaper_config" ]; then
      wallpaper="$(${pkgs.gnused}/bin/sed -n 's/^[[:space:]]*path=//p' "$hyprpaper_config" | ${pkgs.coreutils}/bin/head -n1)"
    fi
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -n "$wallpaper" ] && ${pkgs.systemd}/bin/systemctl --user is-active --quiet hyprpaper.service; then
      ${pkgs.hyprland}/bin/hyprctl monitors -j \
        | ${pkgs.jq}/bin/jq -r '.[].name' \
        | while IFS= read -r monitor; do
            [ -n "$monitor" ] && ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >/dev/null
          done
    fi
  '';
}
