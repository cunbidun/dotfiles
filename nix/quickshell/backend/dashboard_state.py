#!/usr/bin/env python3
"""Dashboard state polling for Quickshell.

This module is intentionally separate from the BlueZ agent code. The backend
service starts it as a daemon thread and QML reads the latest JSON snapshot.
"""
import json
import os
import re
import shutil
import subprocess
import tempfile
import threading
import time
from pathlib import Path


DEFAULT_INTERVAL_MS = 2500


def default_state_path():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    return os.path.join(runtime_dir, "quickshell-cunbidun", "dashboard-state.json")


def poll_interval_ms():
    raw = os.environ.get("QUICKSHELL_DASHBOARD_STATE_INTERVAL_MS", "")
    try:
        return max(250, int(raw)) if raw else DEFAULT_INTERVAL_MS
    except ValueError:
        return DEFAULT_INTERVAL_MS


def run_text(args, timeout=1.5):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=False)
    except (FileNotFoundError, subprocess.SubprocessError):
        return ""
    return result.stdout.strip()


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def read_int(path):
    value = read_text(path)
    try:
        return int(value)
    except ValueError:
        return None


def human_size(bytes_value):
    units = ("B", "K", "M", "G", "T")
    value = float(bytes_value)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.0f}{unit}"
        value /= 1024
    return f"{value:.0f}T"


def cpu_totals():
    fields = read_text("/proc/stat").splitlines()[0].split()[1:]
    values = [int(field) for field in fields]
    idle = values[3] + values[4]
    total = sum(values)
    return total, idle


def memory_value():
    values = {}
    for line in read_text("/proc/meminfo").splitlines():
        parts = line.split()
        if len(parts) >= 2:
            values[parts[0].rstrip(":")] = int(parts[1])
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", 0)
    used_gib = (total - available) // 1048576
    total_gib = total // 1048576
    return f"{used_gib}/{total_gib} GiB"


def disk_value():
    usage = shutil.disk_usage("/")
    return f"{human_size(usage.used)}/{human_size(usage.total)}"


def uptime_value():
    seconds_text = read_text("/proc/uptime").split()[0]
    seconds = int(float(seconds_text))
    return f"{seconds // 3600}h {(seconds % 3600) // 60:02d}m"


def cpu_temp_value():
    for path in Path("/sys/class/thermal").glob("thermal_zone*/temp"):
        value = read_int(path)
        if value is not None and 1000 < value < 110000:
            return f"{value // 1000}C"
    return "--"


def nvidia_gpu_values():
    output = run_text([
        "nvidia-smi",
        "--query-gpu=utilization.gpu,temperature.gpu",
        "--format=csv,noheader,nounits",
    ])
    if not output:
        return None
    parts = [part.strip() for part in output.splitlines()[0].split(",")]
    if len(parts) < 2:
        return None
    return {"gpu": f"{parts[0]}%", "gpu_temp": f"{parts[1]}C"}


def sysfs_gpu_values():
    gpu = "0%"
    gpu_temp = "--"
    for path in Path("/sys/class/drm").glob("card*/device/gpu_busy_percent"):
        value = read_int(path)
        if value is not None:
            gpu = f"{value}%"
            break
    for path in Path("/sys/class/drm").glob("card*/device/hwmon/hwmon*/temp1_input"):
        value = read_int(path)
        if value is not None:
            gpu_temp = f"{value // 1000}C"
            break
    return {"gpu": gpu, "gpu_temp": gpu_temp}


def volume_value():
    output = run_text(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    match = re.search(r"Volume:\s+([0-9.]+)", output)
    if not match:
        return 43
    return round(float(match.group(1)) * 100)


def audio_outputs_value():
    output = run_text(["wpctl", "status"])
    outputs = []
    in_sinks = False
    for line in output.splitlines():
        if "Sinks:" in line:
            in_sinks = True
            continue
        if in_sinks and "Sources:" in line:
            break
        if not in_sinks:
            continue
        match = re.search(r"([^0-9]*)(\d+)\.\s+(.*?)(?:\s+\[vol:.*)?$", line)
        if not match:
            continue
        prefix, sink_id, name = match.groups()
        outputs.append({"id": sink_id, "active": "*" in prefix, "name": name.strip()})
    return outputs


def brightness_value():
    output = run_text(["brightnessctl", "-m"])
    parts = output.split(",")
    if len(parts) >= 4:
        try:
            return int(parts[3].rstrip("%"))
        except ValueError:
            pass
    return 58


def recording_value():
    script = Path.home() / "dotfiles/nix/quickshell/scripts/screen_record.sh"
    if not script.exists():
        return "not recording"
    output = run_text([str(script), "status"])
    return output or "not recording"


def nightlight_value():
    output = run_text(["systemctl", "--user", "is-active", "hyprsunset.service"])
    return output or "inactive"


class DashboardStatePoller:
    def __init__(self, path=None, interval_ms=None):
        self.path = path or default_state_path()
        self.interval_ms = interval_ms or poll_interval_ms()
        self.stop_event = threading.Event()
        self.last_cpu = None
        self.last_net = None
        self.last_net_time = None

    def start(self):
        threading.Thread(target=self.run, daemon=True).start()

    def run(self):
        while not self.stop_event.is_set():
            try:
                self.write_state(self.collect())
            except Exception as exc:
                print(f"quickshell-dashboard-state error: {exc}", flush=True)
            self.stop_event.wait(self.interval_ms / 1000)

    def collect(self):
        state = {
            "cpu": self.cpu_percent(),
            "cpu_temp": cpu_temp_value(),
            "ram": memory_value(),
            "disk": disk_value(),
            "load": " ".join(read_text("/proc/loadavg").split()[:3]),
            "uptime": uptime_value(),
            "net": self.net_value(),
            "volume": volume_value(),
            "audio_outputs": audio_outputs_value(),
            "brightness": brightness_value(),
            "recording": recording_value(),
            "nightlight": nightlight_value(),
        }
        state.update(nvidia_gpu_values() or sysfs_gpu_values())
        return state

    def cpu_percent(self):
        current = cpu_totals()
        if self.last_cpu is None:
            self.last_cpu = current
            return 0
        total_delta = current[0] - self.last_cpu[0]
        idle_delta = current[1] - self.last_cpu[1]
        self.last_cpu = current
        if total_delta <= 0:
            return 0
        return round(100 * (total_delta - idle_delta) / total_delta)

    def net_value(self):
        rx = 0
        tx = 0
        for line in read_text("/proc/net/dev").splitlines():
            if ":" not in line:
                continue
            iface, data = line.split(":", 1)
            if iface.strip() == "lo":
                continue
            fields = data.split()
            if len(fields) >= 16:
                rx += int(fields[0])
                tx += int(fields[8])
        now = time.monotonic()
        if self.last_net is None or self.last_net_time is None:
            self.last_net = (rx, tx)
            self.last_net_time = now
            return "\u2193 0 K/s    \u2191 0 K/s"
        elapsed = max(now - self.last_net_time, 0.001)
        rx_rate = max(0, (rx - self.last_net[0]) / elapsed / 1024)
        tx_rate = max(0, (tx - self.last_net[1]) / elapsed / 1024)
        self.last_net = (rx, tx)
        self.last_net_time = now
        return f"\u2193 {rx_rate:.0f} K/s    \u2191 {tx_rate:.0f} K/s"

    def write_state(self, state):
        os.makedirs(os.path.dirname(self.path), mode=0o700, exist_ok=True)
        fd, temp_path = tempfile.mkstemp(prefix="dashboard-state.", dir=os.path.dirname(self.path))
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump(state, handle, separators=(",", ":"))
                handle.write("\n")
            os.chmod(temp_path, 0o600)
            os.replace(temp_path, self.path)
        finally:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
