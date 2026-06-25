{...}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
    };
  };

  systemd.user.services.hyprpaper.Unit.X-SwitchMethod = "keep-old";
}
