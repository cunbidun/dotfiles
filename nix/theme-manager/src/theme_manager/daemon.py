#!/usr/bin/env python3
import os, socket, yaml, subprocess, sys, threading, fcntl
import json  # for JSON encoding

import time
from .tray import ThemeManagerTray

CONFIG_PATH = os.path.expanduser("~/.config/theme-manager/config.yaml")
STATE_PATH = os.path.expanduser("~/.local/share/theme-manager/state")
SOCKET_PATH = os.path.expanduser("~/.local/share/theme-manager/socket")
LOCK_PATH = os.path.expanduser("~/.local/share/theme-manager/lock")

class ThemeManagerDaemon:
    """Encapsulated daemon replacing previous global-state implementation."""

    def __init__(self):
        self.config = self._load_config()
        self.allowed = self.config["themes"]
        self.current_theme = self._load_state(self.allowed[0])
        if self.current_theme not in self.allowed:
            self.current_theme = self.allowed[0]
            self._save_state(self.current_theme)

        self.lock = threading.Lock()
        self.script_running = False  # guarded by self.lock
        self.server_socket = None
        self._accept_thread = None
        self.tray: ThemeManagerTray | None = None  # tray instance (optional)

    # ---------- config & state helpers ---------- #
    def _load_config(self):
        cfg = yaml.safe_load(open(CONFIG_PATH))
        script = os.path.expanduser(cfg["script"])

        if not os.path.exists(script) or not os.path.isfile(script):
            print(f"ERROR: script '{script}' does not exist or is not a file", file=sys.stderr)
            sys.exit(1)

        if not os.access(script, os.X_OK):
            print(f"ERROR: script '{script}' is not executable", file=sys.stderr)
            sys.exit(1)

        cfg["script"] = script
        if "nvimThemeMap" not in cfg:
            cfg["nvimThemeMap"] = {}
        return cfg

    def _load_state(self, default):
        try:
            return open(STATE_PATH).read().strip()
        except FileNotFoundError:
            return default

    def _save_state(self, theme):
        os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
        open(STATE_PATH, "w").write(theme)

    # ---------- system helpers ---------- #
    def _notify(self, summary: str, body: str = ""):
        try:
            subprocess.Popen(["notify-send", summary, body])
        except FileNotFoundError:
            pass

    def _get_polarity(self):
        try:
            result = subprocess.run(["darkman", "get"], capture_output=True, text=True, timeout=5)
            return result.stdout.strip() if result.returncode == 0 else "dark"
        except Exception:
            return "dark"

    def _set_polarity(self, polarity: str) -> bool:
        if polarity not in ("light", "dark"):
            return False
        try:
            subprocess.run(["darkman", "set", polarity], check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def _toggle_polarity(self) -> str:
        current = self._get_polarity()
        new = "light" if current == "dark" else "dark"
        return new if self._set_polarity(new) else current

    # ---------- concurrency helpers ---------- #
    def _acquire_write(self, conn) -> bool:
        with self.lock:
            if self.script_running:
                conn.sendall(b"ERROR script busy\n")
                return False
            self.script_running = True
            return True

    def _release_write(self):
        with self.lock:
            self.script_running = False

    # ---------- command handlers ---------- #
    def _handle_set_polarity(self, conn, pol: str):
        if not self._acquire_write(conn):
            return
        if self._set_polarity(pol):
            self._notify("Polarity Changed", f"Polarity set to {pol}")
            conn.sendall(f"OK {pol}\n".encode())
        else:
            conn.sendall(b"ERROR invalid polarity\n")
        self._release_write()

    def _handle_toggle_polarity(self, conn):
        if not self._acquire_write(conn):
            return
        new_pol = self._toggle_polarity()
        self._notify("Polarity Toggled", f"Now {new_pol}")
        conn.sendall(f"OK {new_pol}\n".encode())
        self._release_write()

    def _handle_set_theme(self, conn, theme: str):
        if not self._acquire_write(conn):
            return
        try:
            self.current_theme = theme
            self._save_state(self.current_theme)
            proc = subprocess.Popen([self.config["script"], theme])
        except Exception as e:
            self._release_write()
            conn.sendall(f"ERROR failed to launch script: {e}\n".encode())
            return

        def _wait(p):
            p.wait()
            self._release_write()
        threading.Thread(target=_wait, args=(proc,), daemon=True).start()

        self._notify("Theme Changed", f"Theme set to {self.current_theme}")
        conn.sendall(f"OK {self.current_theme}\n".encode())

    # ---------- client handling ---------- #
    def _handle_client(self, conn: socket.socket):
        with conn:
            data = conn.recv(1024).decode().strip().split(maxsplit=1)
            if not data or not data[0]:
                return
            cmd = data[0]

            if cmd == "GET-THEME":
                conn.sendall(f"OK {self.current_theme}\n".encode())
            elif cmd == "LIST-THEMES":
                conn.sendall(f"OK {json.dumps(self.allowed)}\n".encode())
            elif cmd == "GET-POLARITY":
                conn.sendall(f"OK {self._get_polarity()}\n".encode())
            elif cmd == "SET-POLARITY" and len(data) == 2:
                self._handle_set_polarity(conn, data[1])
            elif cmd == "TOGGLE-POLARITY":
                self._handle_toggle_polarity(conn)
            elif cmd == "GET-NVIM-THEME":
                try:
                    pol = self._get_polarity()
                except Exception:
                    pol = "dark"
                key = f"{self.current_theme}-{pol}"
                if key in self.config["nvimThemeMap"]:
                    conn.sendall(f"OK {self.config['nvimThemeMap'][key]}\n".encode())
                else:
                    conn.sendall(f"ERROR no nvim theme mapping for '{key}'\n".encode())
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

        def _loop():
            while True:
                conn, _ = self.server_socket.accept()
                threading.Thread(target=self._handle_client, args=(conn,), daemon=True).start()

        if background:
            self._accept_thread = threading.Thread(target=_loop, daemon=True)
            self._accept_thread.start()
        else:
            _loop()

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