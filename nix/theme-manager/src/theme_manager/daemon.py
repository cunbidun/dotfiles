#!/usr/bin/env python3
import os, socket, yaml, subprocess, sys, threading, fcntl
import json  # for JSON encoding
import time
from datetime import datetime, timezone, timedelta

from astral import LocationInfo
from astral.sun import sun

from .runtime import apply_theme
from .tray import ThemeManagerTray

CONFIG_PATH = os.path.expanduser("~/.config/theme-manager/config.yaml")
THEME_STATE_PATH = os.path.expanduser("~/.local/state/theme-manager/current-theme-name.txt")
SOCKET_PATH = os.path.expanduser("~/.local/share/theme-manager/socket")
LOCK_PATH = os.path.expanduser("~/.local/share/theme-manager/lock")
OVERRIDE_PATH = os.path.expanduser("~/.local/state/theme-manager/polarity-override.json")

class ThemeManagerDaemon:
    """Encapsulated daemon replacing previous global-state implementation."""

    def __init__(self):
        self.config = self._load_config()
        self.allowed = self.config["themes"]
        self.current_theme, self.current_polarity = self._load_current_state()

        self.lock = threading.Lock()
        self.theme_change_running = False  # guarded by self.lock
        self.server_socket = None
        self._accept_thread = None
        self._scheduler_thread = None
        self.tray: ThemeManagerTray | None = None  # tray instance (optional)

    # ---------- config & state helpers ---------- #
    def _load_config(self):
        return yaml.safe_load(open(CONFIG_PATH))

    def _split_theme_name(self, theme_name: str) -> tuple[str, str] | None:
        if "-" not in theme_name:
            return None
        theme, polarity = theme_name.rsplit("-", 1)
        if theme not in self.allowed or polarity not in ("light", "dark"):
            return None
        return theme, polarity

    def _load_current_state(self) -> tuple[str, str]:
        try:
            parsed = self._split_theme_name(self._get_theme_state_name())
        except FileNotFoundError:
            parsed = None
        if parsed is None:
            return self.allowed[0], "dark"
        return parsed

    def _format_duration(self, delta: timedelta) -> str:
        seconds = max(0, int(delta.total_seconds()))
        hours, seconds = divmod(seconds, 3600)
        minutes, seconds = divmod(seconds, 60)
        if hours:
            return f"{hours}h {minutes}m"
        if minutes:
            return f"{minutes}m {seconds}s"
        return f"{seconds}s"

    def _read_location(self) -> tuple[float, float]:
        location_file = self.config.get("locationFile", "/etc/geolocation")
        with open(os.path.expanduser(location_file), "r") as f:
            values = [line.strip() for line in f if line.strip() and not line.lstrip().startswith("#")]
        if len(values) < 2:
            raise RuntimeError(f"location file missing latitude/longitude: {location_file}")
        return float(values[0]), float(values[1])

    def _sun_window(self, now: datetime) -> tuple[datetime, datetime]:
        lat, lon = self._read_location()
        location = LocationInfo(latitude=lat, longitude=lon)
        local_now = now.astimezone()
        times = sun(location.observer, date=local_now.date(), tzinfo=local_now.tzinfo)
        return times["sunrise"], times["sunset"]

    def _scheduled_polarity(self, now: datetime | None = None) -> tuple[str, datetime]:
        now = now or datetime.now(timezone.utc)
        sunrise, sunset = self._sun_window(now)

        if sunrise <= now < sunset:
            return "light", sunset

        if now < sunrise:
            return "dark", sunrise

        tomorrow = now + timedelta(days=1)
        next_sunrise, _ = self._sun_window(tomorrow)
        return "dark", next_sunrise

    def _log_next_switch(self, polarity: str, next_switch: datetime):
        now = datetime.now(timezone.utc)
        next_polarity = "dark" if polarity == "light" else "light"
        print(
            f"Auto polarity status: scheduled={polarity}, next={next_polarity}, at="
            f"{next_switch.astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')} "
            f"(in {self._format_duration(next_switch - now)})",
            flush=True,
        )

    def _schedule_status(self) -> dict[str, str | bool]:
        scheduled, next_switch = self._scheduled_polarity()
        current = self._get_polarity()
        next_polarity = "dark" if scheduled == "light" else "light"
        now = datetime.now(timezone.utc)
        override = self._load_override(now)
        return {
            "enabled": bool(self.config.get("autoSwitch", True)),
            "current": current,
            "scheduled": scheduled,
            "next": next_polarity,
            "override": override is not None,
            "overrideUntil": override["until"].astimezone().strftime("%H:%M") if override else "",
            "overrideRemaining": self._format_duration(override["until"] - now) if override else "",
            "at": next_switch.astimezone().strftime("%H:%M"),
            "remaining": self._format_duration(next_switch - now),
        }

    def _load_override(self, now: datetime | None = None):
        now = now or datetime.now(timezone.utc)
        try:
            with open(OVERRIDE_PATH, "r") as f:
                data = json.load(f)
            until = datetime.fromisoformat(data["until"])
            if until.tzinfo is None:
                until = until.replace(tzinfo=timezone.utc)
            if until <= now or data.get("polarity") not in ("light", "dark"):
                self._clear_override()
                return None
            return {"polarity": data["polarity"], "until": until}
        except FileNotFoundError:
            return None
        except Exception:
            self._clear_override()
            return None

    def _write_override(self, polarity: str, until: datetime):
        os.makedirs(os.path.dirname(OVERRIDE_PATH), exist_ok=True)
        with open(OVERRIDE_PATH, "w") as f:
            json.dump({"polarity": polarity, "until": until.isoformat()}, f)

    def _clear_override(self):
        try:
            os.unlink(OVERRIDE_PATH)
        except FileNotFoundError:
            pass

    def _record_manual_polarity(self, polarity: str):
        scheduled, next_switch = self._scheduled_polarity()
        if polarity == scheduled:
            self._clear_override()
        else:
            self._write_override(polarity, next_switch)

    def _auto_switch_loop(self):
        if not self.config.get("autoSwitch", True):
            print("Auto polarity disabled", flush=True)
            return

        try:
            self._apply_current_theme()
        except Exception as e:
            print(f"ERROR initial theme apply failed: {e}", file=sys.stderr, flush=True)

        while True:
            try:
                polarity, next_switch = self._scheduled_polarity()
                self._log_next_switch(polarity, next_switch)
                self._update_tray()

                override = self._load_override()
                if override is not None:
                    if self._get_polarity() != override["polarity"]:
                        self._apply_auto_polarity(override["polarity"])
                    wait_until = min(next_switch, override["until"])
                    print(
                        f"Auto polarity override active until "
                        f"{override['until'].astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')} "
                        f"(in {self._format_duration(override['until'] - datetime.now(timezone.utc))})",
                        flush=True,
                    )
                else:
                    wait_until = next_switch
                    if self._get_polarity() != polarity:
                        self._apply_auto_polarity(polarity)

                while True:
                    remaining = int((wait_until - datetime.now(timezone.utc)).total_seconds())
                    if remaining <= 0:
                        break
                    time.sleep(min(60, remaining))
                    if remaining > 60:
                        self._log_next_switch(polarity, next_switch)
                        self._update_tray()

                target, _ = self._scheduled_polarity(datetime.now(timezone.utc) + timedelta(seconds=5))
                if self._get_polarity() != target:
                    self._clear_override()
                    self._apply_auto_polarity(target)
            except Exception as e:
                print(f"ERROR auto polarity failed: {e}", file=sys.stderr, flush=True)
                time.sleep(300)

    def _apply_auto_polarity(self, polarity: str):
        acquired = False
        with self.lock:
            if self.theme_change_running:
                print("Auto polarity skipped: theme switch already running", flush=True)
            else:
                self.theme_change_running = True
                acquired = True
        if acquired:
            try:
                self._apply_polarity(polarity)
            finally:
                self._release_write()
                self._update_tray()

    # ---------- system helpers ---------- #
    def _notify(self, summary: str, body: str = ""):
        try:
            subprocess.Popen(["notify-send", summary, body])
        except FileNotFoundError:
            pass

    def _get_polarity(self):
        return self.current_polarity

    def _get_theme_state_name(self):
        with open(THEME_STATE_PATH, 'r') as f:
            return f.read().strip()

    def _apply_polarity(self, polarity: str) -> bool:
        if polarity not in ("light", "dark"):
            return False
        old_polarity = self.current_polarity
        self.current_polarity = polarity
        try:
            active = apply_theme(self.current_theme, polarity)
        except Exception:
            self.current_polarity = old_polarity
            raise
        expected = f"{self.current_theme}-{polarity}"
        if active != expected:
            self.current_polarity = old_polarity
            raise RuntimeError(f"active theme is {active}, expected {expected}")
        return True

    def _apply_current_theme(self) -> bool:
        active = apply_theme(self.current_theme, self.current_polarity)
        expected = f"{self.current_theme}-{self.current_polarity}"
        if active != expected:
            raise RuntimeError(f"active theme is {active}, expected {expected}")
        return True

    def _toggle_polarity(self) -> str:
        current = self._get_polarity()
        new = "light" if current == "dark" else "dark"
        return new if self._apply_polarity(new) else current

    # ---------- concurrency helpers ---------- #
    def _acquire_write(self, conn) -> bool:
        with self.lock:
            if self.theme_change_running:
                conn.sendall(b"ERROR theme change busy\n")
                return False
            self.theme_change_running = True
            return True

    def _release_write(self):
        with self.lock:
            self.theme_change_running = False

    # ---------- command handlers ---------- #
    def _handle_set_polarity(self, conn, pol: str):
        if not self._acquire_write(conn):
            return
        try:
            if self._apply_polarity(pol):
                self._record_manual_polarity(pol)
                self._notify("Polarity Changed", f"Polarity set to {pol}")
                conn.sendall(f"OK {pol}\n".encode())
            else:
                conn.sendall(b"ERROR invalid polarity\n")
        finally:
            self._release_write()
            self._update_tray()

    def _handle_toggle_polarity(self, conn):
        if not self._acquire_write(conn):
            return
        try:
            new_pol = self._toggle_polarity()
            self._record_manual_polarity(new_pol)
            self._notify("Polarity Toggled", f"Now {new_pol}")
            conn.sendall(f"OK {new_pol}\n".encode())
        finally:
            self._release_write()
            self._update_tray()

    def _handle_set_theme(self, conn, theme: str):
        if not self._acquire_write(conn):
            return
        old_theme = self.current_theme
        old_polarity = self.current_polarity
        try:
            polarity = self._get_polarity()
            self.current_theme = theme
            self.current_polarity = polarity
            active = apply_theme(theme, polarity)
        except Exception as e:
            self.current_theme = old_theme
            self.current_polarity = old_polarity
            self._release_write()
            conn.sendall(f"ERROR failed to apply theme: {e}\n".encode())
            return

        try:
            expected = f"{theme}-{polarity}"
            if active != expected:
                self.current_theme = old_theme
                self.current_polarity = old_polarity
                conn.sendall(f"ERROR active theme is {active}, expected {expected}\n".encode())
                return
            self._notify("Theme Changed", f"Theme set to {theme}")
            conn.sendall(f"OK {theme}\n".encode())
        finally:
            self._release_write()
            self._update_tray()

    def _update_tray(self):
        if self.tray:
            self.tray.refresh_menu()

    # ---------- client handling ---------- #
    def _handle_client(self, conn: socket.socket):
        with conn:
            data = conn.recv(1024).decode().strip().split(maxsplit=1)
            if not data or not data[0]:
                return
            cmd = data[0]

            if cmd == "GET-THEME":
                conn.sendall(f"OK {self.current_theme}\n".encode())
            elif cmd == "GET-POLARITY":
                conn.sendall(f"OK {self._get_polarity()}\n".encode())
            elif cmd == "GET-SCHEDULE":
                conn.sendall(f"OK {json.dumps(self._schedule_status())}\n".encode())
            elif cmd == "LIST-THEMES":
                conn.sendall(f"OK {json.dumps(self.allowed)}\n".encode())
            elif cmd == "SET-POLARITY" and len(data) == 2:
                self._handle_set_polarity(conn, data[1])
            elif cmd == "TOGGLE-POLARITY":
                self._handle_toggle_polarity(conn)
            elif cmd == "SET-THEME" and len(data) == 2:
                theme = data[1]
                if theme not in self.allowed:
                    conn.sendall(b"ERROR invalid theme\n")
                else:
                    self._handle_set_theme(conn, theme)
            else:
                conn.sendall(b"ERROR unknown command\n")

    # ---------- server lifecycle ---------- #
    def start(self, background: bool = False):
        try:
            os.unlink(SOCKET_PATH)
        except FileNotFoundError:
            pass
        os.makedirs(os.path.dirname(SOCKET_PATH), exist_ok=True)
        self.server_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server_socket.bind(SOCKET_PATH)
        os.chmod(SOCKET_PATH, 0o600)
        self.server_socket.listen(5)

        print("Theme manager daemon started")
        self._scheduler_thread = threading.Thread(target=self._auto_switch_loop, daemon=True)
        self._scheduler_thread.start()

        def _loop():
            while True:
                conn, _ = self.server_socket.accept()
                threading.Thread(target=self._handle_client, args=(conn,), daemon=True).start()

        if background:
            self._accept_thread = threading.Thread(target=_loop, daemon=True)
            self._accept_thread.start()
        else:
            _loop()

    def stop(self):
        """Stop the daemon and cleanup resources."""
        if self.server_socket:
            self.server_socket.close()
        try:
            os.unlink(SOCKET_PATH)
        except FileNotFoundError:
            pass

def run_with_tray():
    """Run daemon plus tray with tray as daemon property."""
    # ---- single-instance guard ---- #
    os.makedirs(os.path.dirname(LOCK_PATH), exist_ok=True)
    try:
        lock_fd = os.open(LOCK_PATH, os.O_CREAT | os.O_RDWR)
        try:
            fcntl.lockf(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            print("theme-manager: another instance is already running (lock)")
            return
    except Exception as e:
        print(f"theme-manager: failed to create lock file: {e}")

    # secondary guard: live socket present
    if os.path.exists(SOCKET_PATH):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCKET_PATH)
                print("theme-manager: another instance detected via socket; exiting")
                return
        except Exception:
            pass  # stale socket

    daemon = ThemeManagerDaemon()
    daemon.start(background=True)
    time.sleep(0.4)
    print("Starting theme manager daemon with tray...")
    daemon.tray = ThemeManagerTray()
    daemon.tray.run()


def main():
    run_with_tray()
