{
  pkgs,
  userdata,
  ...
}: let
  hyprctl = "/etc/profiles/per-user/${userdata.username}/bin/hyprctl";
  nightTemp = 4500;

  hyprsunsetGeoclue = pkgs.writeTextFile {
    name = "hyprsunset-geoclue";
    executable = true;
    destination = "/bin/hyprsunset-geoclue";
    text = ''
      #!${
        pkgs.python3.withPackages (p: [p.astral p.dbus-python])
      }/bin/python3
      import dbus
      import datetime
      import time
      import subprocess

      NIGHT_TEMP = ${toString nightTemp}
      HYPRCTL = "${hyprctl}"


      def get_location():
          bus = dbus.SystemBus()
          manager_obj = bus.get_object(
              "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager"
          )
          manager = dbus.Interface(manager_obj, "org.freedesktop.GeoClue2.Manager")
          client_path = str(manager.GetClient())

          client_obj = bus.get_object("org.freedesktop.GeoClue2", client_path)
          props = dbus.Interface(client_obj, "org.freedesktop.DBus.Properties")
          props.Set(
              "org.freedesktop.GeoClue2.Client", "DesktopId", "hyprsunset-geoclue"
          )
          # City-level accuracy is sufficient for sunrise/sunset
          props.Set(
              "org.freedesktop.GeoClue2.Client",
              "RequestedAccuracyLevel",
              dbus.UInt32(4),
          )

          client = dbus.Interface(client_obj, "org.freedesktop.GeoClue2.Client")
          client.Start()

          for _ in range(30):
              location_path = str(
                  props.Get("org.freedesktop.GeoClue2.Client", "Location")
              )
              if location_path != "/":
                  break
              time.sleep(1)
          else:
              client.Stop()
              raise RuntimeError("Timed out waiting for geoclue location")

          location_obj = bus.get_object("org.freedesktop.GeoClue2", location_path)
          loc_props = dbus.Interface(location_obj, "org.freedesktop.DBus.Properties")
          lat = float(loc_props.Get("org.freedesktop.GeoClue2.Location", "Latitude"))
          lon = float(loc_props.Get("org.freedesktop.GeoClue2.Location", "Longitude"))
          client.Stop()
          return lat, lon


      def apply_temperature(is_night):
          if is_night:
              subprocess.run([HYPRCTL, "hyprsunset", "temperature", str(NIGHT_TEMP)])
          else:
              subprocess.run([HYPRCTL, "hyprsunset", "identity"])


      def main():
          from astral import LocationInfo
          from astral.sun import sun

          lat, lon = get_location()
          print(f"Location: {lat:.4f}, {lon:.4f}", flush=True)
          location = LocationInfo(latitude=lat, longitude=lon)

          last_state = None  # True=night, False=day

          while True:
              now = datetime.datetime.now(datetime.timezone.utc)
              s = sun(location.observer, date=now.date())
              sunrise, sunset = s["sunrise"], s["sunset"]
              is_night = not (sunrise <= now < sunset)
              if is_night != last_state:
                  apply_temperature(is_night)
                  print(
                      f"{'Night' if is_night else 'Day'} mode applied (sunrise={sunrise.strftime('%H:%M')}, sunset={sunset.strftime('%H:%M')} UTC)",
                      flush=True,
                  )
                  last_state = is_night

              time.sleep(10)


      main()
    '';
  };
in {
  home.packages = [hyprsunsetGeoclue];

  services.hyprsunset.enable = true;

  systemd.user.services.hyprsunset-geoclue = {
    Unit = {
      Description = "hyprsunset color temperature controller via geoclue";
      After = ["graphical-session.target" "hyprsunset.service"];
      Wants = ["hyprsunset.service"];
      # Don't start if the geolocation secret hasn't been decrypted yet
      ConditionPathExists = "/etc/geolocation";
    };
    Service = {
      ExecStart = "${hyprsunsetGeoclue}/bin/hyprsunset-geoclue";
      Restart = "on-failure";
      RestartSec = "30s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
