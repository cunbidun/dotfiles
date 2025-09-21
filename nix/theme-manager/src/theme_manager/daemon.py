#!/usr/bin/env python3
import os, socket, yaml, subprocess, sys, threading, fcntl
import json  # for JSON encoding

from .tray import ThemeManagerTray

CONFIG_PATH = os.path.expanduser("~/.config/theme-manager/config.yaml")
STATE_PATH = os.path.expanduser("~/.local/share/theme-manager/state")
SOCKET_PATH = os.path.expanduser("~/.local/share/theme-manager/socket")
LOCK_PATH = os.path.expanduser("~/.local/share/theme-manager/lock")

# Global execution state
script_lock = threading.Lock()
script_running = False  # guarded by script_lock

def load_config():
    cfg = yaml.safe_load(open(CONFIG_PATH))
    script = os.path.expanduser(cfg["script"])

    if not os.path.exists(script) or not os.path.isfile(script):
        print(f"ERROR: script '{script}' does not exist or is not a file", file=sys.stderr)
        sys.exit(1)

    if not os.access(script, os.X_OK):
        print(f"ERROR: script '{script}' is not executable", file=sys.stderr)
        sys.exit(1)

    cfg["script"] = script
    
    # Set default nvim theme mappings if not provided
    if "nvimThemeMap" not in cfg:
        cfg["nvimThemeMap"] = {}
        
    return cfg

def load_state(default):
    try:
        return open(STATE_PATH).read().strip()
    except FileNotFoundError:
        return default

def save_state(theme):
    os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
    open(STATE_PATH, "w").write(theme)

def trigger_script(script, theme):
    subprocess.Popen([script, theme])

def notify(summary: str, body: str = ""):
    try:
        subprocess.Popen(["notify-send", summary, body])
    except FileNotFoundError:
        pass

def get_polarity():
    try:
        result = subprocess.run(["darkman", "get"], capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else "dark"
    except Exception:
        return "dark"

def set_polarity(polarity: str) -> bool:
    if polarity not in ("light", "dark"):
        return False
    try:
        subprocess.run(["darkman", "set", polarity], check=True)
        return True
    except subprocess.CalledProcessError:
        return False

def toggle_polarity() -> str:
    current = get_polarity()
    new = "light" if current == "dark" else "dark"
    return new if set_polarity(new) else current

# ------------- unified exclusive write decorator ------------- #
def exclusive_write(handler):
    """Ensure only one write (theme or polarity change) at a time.

    Handler is responsible for calling release_write() when work that blocks further
    writes is complete. Theme changes release after external script finishes; quick
    polarity changes release immediately.
    """
    def wrapped(conn, *args, **kwargs):
        global script_running
        with script_lock:
            if script_running:
                conn.sendall(b"ERROR script busy\n")
                return
            script_running = True
        return handler(conn, *args, **kwargs)
    return wrapped

def release_write():
    """Release write exclusivity (idempotent)."""
    global script_running
    with script_lock:
        script_running = False

def run_daemon_only():
    """Run only the daemon (no tray)"""
    cfg = load_config()
    allowed = cfg["themes"]
    curr = load_state(allowed[0])
    if curr not in allowed:
        curr = allowed[0]
    save_state(curr)

    try:
        os.unlink(SOCKET_PATH)
    except FileNotFoundError:
        pass

    os.makedirs(os.path.dirname(SOCKET_PATH), exist_ok=True)
    serv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    serv.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o600)
    serv.listen(1)

    # --- command handlers (some decorated) --- #
    @exclusive_write
    def handle_set_polarity(conn, pol):
        if set_polarity(pol):
            notify("Polarity Changed", f"Polarity set to {pol}")
            conn.sendall(f"OK {pol}\n".encode())
        else:
            conn.sendall(b"ERROR invalid polarity\n")
        release_write()

    @exclusive_write
    def handle_toggle_polarity(conn):
        new_pol = toggle_polarity()
        notify("Polarity Toggled", f"Now {new_pol}")
        conn.sendall(f"OK {new_pol}\n".encode())
        release_write()

    @exclusive_write
    def handle_set_theme(conn, theme):
        nonlocal curr
        global script_running
        try:
            # Update state (no contention; script_running already reserved)
            curr = theme
            save_state(curr)
            proc = subprocess.Popen([cfg["script"], theme])
        except Exception as e:
            # Release reservation on failure
            release_write()
            conn.sendall(f"ERROR failed to launch script: {e}\n".encode())
            return

        def _wait_proc(p):
            p.wait()
            release_write()
        threading.Thread(target=_wait_proc, args=(proc,), daemon=True).start()

        notify("Theme Changed", f"Theme set to {curr}")
        conn.sendall(f"OK {curr}\n".encode())

    def handle_client(conn):
        nonlocal curr  # current theme needs to be mutated
        with conn:
            data = conn.recv(1024).decode().strip().split(maxsplit=1)
            cmd = data[0]

            if cmd == "GET-THEME":
                conn.sendall(f"OK {curr}\n".encode())

            elif cmd == "LIST-THEMES":
                # Return themes as JSON
                payload = json.dumps(allowed)
                conn.sendall(f"OK {payload}\n".encode())

            elif cmd == "GET-POLARITY":
                pol = get_polarity()
                conn.sendall(f"OK {pol}\n".encode())

            elif cmd == "SET-POLARITY" and len(data) == 2:
                handle_set_polarity(conn, data[1])

            elif cmd == "TOGGLE-POLARITY":
                handle_toggle_polarity(conn)

            elif cmd == "GET-NVIM-THEME":
                # Return nvim theme for current theme with polarity, error if not mapped
                # Get current polarity from darkman
                try:
                    result = subprocess.run(["darkman", "get"], capture_output=True, text=True, timeout=5)
                    polarity = result.stdout.strip() if result.returncode == 0 else "dark"
                except (subprocess.TimeoutExpired, FileNotFoundError):
                    polarity = "dark"  # fallback
                
                # Construct theme key with polarity
                theme_key = f"{curr}-{polarity}"
                
                if theme_key in cfg["nvimThemeMap"]:
                    nvim_theme = cfg["nvimThemeMap"][theme_key]
                    conn.sendall(f"OK {nvim_theme}\n".encode())
                else:
                    conn.sendall(f"ERROR no nvim theme mapping for '{theme_key}'\n".encode())

            elif cmd == "SET-THEME" and len(data) == 2:
                theme = data[1]
                if theme not in allowed:
                    conn.sendall(f"ERROR invalid theme\n".encode())
                else:
                    handle_set_theme(conn, theme)
            else:
                conn.sendall(f"ERROR unknown command\n".encode())

    print("Theme manager daemon started")
    while True:
        conn, _ = serv.accept()
        threading.Thread(target=handle_client, args=(conn,)).start()

def run_with_tray():
    """Run daemon plus strict tray (no fallbacks)."""
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
        # continue without lock (last resort) but still attempt socket check

    # secondary guard: live socket present
    if os.path.exists(SOCKET_PATH):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCKET_PATH)
                print("theme-manager: another instance detected via socket; exiting")
                return
        except Exception:
            # stale socket, will be cleaned by daemon start
            pass

    threading.Thread(target=run_daemon_only, daemon=True).start()
    import time
    time.sleep(0.5)
    print("Starting theme manager daemon with tray...")
    tray_manager = ThemeManagerTray()
    tray_manager.run()

def main():
    run_with_tray()