#!/usr/bin/env python3
import os, socket, yaml, subprocess, sys, threading, fcntl
import json  # for JSON encoding
import time

from .tray import ThemeManagerTray

CONFIG_PATH = os.path.expanduser("~/.config/theme-manager/config.yaml")
STYLIX_THEME_PATH = os.path.expanduser("~/.local/state/stylix/current-theme-name.txt")
SOCKET_PATH = os.path.expanduser("~/.local/share/theme-manager/socket")
LOCK_PATH = os.path.expanduser("~/.local/share/theme-manager/lock")

class ThemeManagerDaemon:
    """Encapsulated daemon replacing previous global-state implementation."""

    def __init__(self):
        self.config = self._load_config()
        self.allowed = self.config["themes"]
        self.current_theme = self._load_current_theme()

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
        return cfg

    def _split_stylix_theme(self, stylix_theme: str) -> tuple[str, str] | None:
        if "-" not in stylix_theme:
            return None
        theme, polarity = stylix_theme.rsplit("-", 1)
        if theme not in self.allowed or polarity not in ("light", "dark"):
            return None
        return theme, polarity

    def _load_current_theme(self) -> str:
        try:
            parsed = self._split_stylix_theme(self._get_stylix_theme_name())
        except FileNotFoundError:
            parsed = None
        if parsed is None:
            return self.allowed[0]
        theme, _ = parsed
        return theme

    # ---------- system helpers ---------- #
    def _notify(self, summary: str, body: str = ""):
        try:
            subprocess.Popen(["notify-send", summary, body])
        except FileNotFoundError:
            pass

    def _get_polarity(self):
        try:
            result = subprocess.run(["darkman", "get"], capture_output=True, text=True, timeout=5)
            polarity = result.stdout.strip()
            if result.returncode == 0 and polarity in ("light", "dark"):
                return polarity
        except Exception:
            pass

        try:
            stylix_theme = self._get_stylix_theme_name()
            if stylix_theme.endswith("-light"):
                return "light"
            if stylix_theme.endswith("-dark"):
                return "dark"
        except Exception:
            return "dark"

    def _get_stylix_theme_name(self):
        with open(STYLIX_THEME_PATH, 'r') as f:
            return f.read().strip()

    def _set_polarity(self, polarity: str) -> bool:
        if polarity not in ("light", "dark"):
            return False
        try:
            if self._get_polarity() == polarity:
                return True
            return subprocess.run(["darkman", "set", polarity], check=False).returncode == 0
        except Exception:
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
        self._update_tray()

    def _handle_toggle_polarity(self, conn):
        if not self._acquire_write(conn):
            return
        new_pol = self._toggle_polarity()
        self._notify("Polarity Toggled", f"Now {new_pol}")
        conn.sendall(f"OK {new_pol}\n".encode())
        self._release_write()
        self._update_tray()

    def _handle_set_theme(self, conn, theme: str):
        if not self._acquire_write(conn):
            return
        try:
            polarity = self._get_polarity()
            proc = subprocess.run([self.config["script"], "-t", theme, "-p", polarity], check=False)
        except Exception as e:
            self._release_write()
            conn.sendall(f"ERROR failed to run script: {e}\n".encode())
            return

        try:
            if proc.returncode != 0:
                conn.sendall(f"ERROR script failed with exit code {proc.returncode}\n".encode())
                return

            try:
                active = self._get_stylix_theme_name()
            except FileNotFoundError:
                conn.sendall(b"ERROR active theme file is missing\n")
                return
            expected = f"{theme}-{polarity}"
            if active != expected:
                conn.sendall(f"ERROR active theme is {active}, expected {expected}\n".encode())
                return

            self.current_theme = theme
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
