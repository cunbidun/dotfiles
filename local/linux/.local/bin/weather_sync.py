import os
import subprocess
from pathlib import Path

import requests
from gi import require_version

require_version("Notify", "0.7")
from pgi.repository import Notify

# Initialize libnotify
Notify.init("Weather Sync")

# Define paths
cache_dir = Path.home() / ".cache"
weather_report_path = cache_dir / "weatherreport"
weather_report_backup_path = cache_dir / "weatherreport.bak"

# Send the initial notification
notification = Notify.Notification.new("Sync weather report", "Updating report...", "weather_sync")
notification.show()

# Backup the existing weather report (if it exists)
if weather_report_path.exists():
    weather_report_path.rename(weather_report_backup_path)

# Download the new weather report
try:
    response = requests.get("https://wttr.in/?m")
    response.raise_for_status()
    weather_report_path.write_bytes(response.content)
except requests.exceptions.RequestException:
    notification = Notify.Notification.new(
        "Something went wrong", "Check your internet connection and try again.", "weather_sync"
    )
    notification.show()
    # Restore the backup if the download failed
    if weather_report_backup_path.exists():
        weather_report_backup_path.rename(weather_report_path)

# Send the completion notification
notification = Notify.Notification.new("Sync weather report", "Sync complete!", "weather_sync")
notification.show()

# Reload dwmblocks and waybar
try:
    subprocess.run(["pkill", "-RTMIN+20", "dwmblocks"], check=True)
except subprocess.CalledProcessError:
    pass

try:
    subprocess.run(["pkill", "-SIGRTMIN+20", "waybar"], check=True)
except subprocess.CalledProcessError:
    pass
