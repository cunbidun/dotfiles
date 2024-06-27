{pkgs, ...}: {
  weather-sync =
    pkgs.writers.writePython3Bin "weather-sync" {
      libraries = [
        pkgs.python311Packages.requests
      ];
      flakeIgnore = [
        "E501" # Line too long
      ];
    } ''
      import os
      import subprocess
      from pathlib import Path
      import requests

      os.system('notify-send -t 3000 "Sync weather report" "Updating report..." -a "weather_sync"')

      # Define paths
      cache_dir = Path.home() / ".cache"
      weather_report_path = cache_dir / "weatherreport"
      weather_report_backup_path = cache_dir / "weatherreport.bak"

      # Backup the existing weather report (if it exists)
      if weather_report_path.exists():
          print("Backingup the old weather report")
          weather_report_path.rename(weather_report_backup_path)

      # Download the new weather report
      try:
          print("Querying https://wttr.in/?m...")
          response = requests.get("https://wttr.in/?m")
          response.raise_for_status()
          print(f"saving response to {weather_report_path}")
          weather_report_path.write_bytes(response.content)
      except requests.exceptions.RequestException:
          os.system('notify-send "Something went wrong. Check your internet connection and try again."')
          if weather_report_backup_path.exists():
              # Restore the backup if the download failed
              weather_report_backup_path.rename(weather_report_path)

      os.system('notify-send -t 3000 "Sync weather report" "Sync complete!" -a "weather_sync"')
      try:
          subprocess.run(["pkill", "-SIGRTMIN+20", "waybar"], check=True)
      except subprocess.CalledProcessError:
          pass
    '';
}
