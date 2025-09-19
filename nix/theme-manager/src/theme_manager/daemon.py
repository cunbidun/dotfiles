#!/usr/bin/env python3
import os, socket, yaml, subprocess, sys, threading
import json  # for JSON encoding

CONFIG_PATH = os.path.expanduser("~/.config/theme-manager/config.yaml")
STATE_PATH = os.path.expanduser("~/.local/share/theme-manager/state")
SOCKET_PATH = os.path.expanduser("~/.local/share/theme-manager/socket")

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

def run():
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

    def handle_client(conn):
        nonlocal curr  # allow updating curr
        with conn:
            data = conn.recv(1024).decode().strip().split(maxsplit=1)
            cmd = data[0]

            if cmd == "GET-THEME":
                conn.sendall(f"OK {curr}\n".encode())

            elif cmd == "LIST-THEMES":
                # Return themes as JSON
                payload = json.dumps(allowed)
                conn.sendall(f"OK {payload}\n".encode())

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
                    curr = theme
                    trigger_script(cfg["script"], theme)
                    save_state(curr)
                    conn.sendall(f"OK {curr}\n".encode())

            else:
                conn.sendall(f"ERROR unknown command\n".encode())

    while True:
        conn, _ = serv.accept()
        threading.Thread(target=handle_client, args=(conn,)).start()

def main():
    run()