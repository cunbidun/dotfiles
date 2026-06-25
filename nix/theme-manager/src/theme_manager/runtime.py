import filecmp
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path


STATE_FILE = Path.home() / ".local/state/theme-manager/current-theme-name.txt"
THEMES_FILE = Path.home() / ".local/share/theme-manager/themes.json"
CHROME_POLICY_DIR = Path.home() / ".local/share/theme-manager/chrome-policy"
CHROME_POLICY_TARGET = Path.home() / ".local/etc/chrome-policy.json"
KITTY_THEME_TARGET = Path.home() / ".local/state/theme-manager/kitty-theme.conf"


def _run(args: list[str], *, check: bool = False, stdout=None, stderr=None) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=check, stdout=stdout, stderr=stderr)


def _is_active(unit: str) -> bool:
    return _run(["systemctl", "--user", "is-active", "--quiet", unit]).returncode == 0


def _current_theme_name() -> str:
    try:
        return STATE_FILE.read_text().strip()
    except FileNotFoundError:
        return ""


def _atomic_write(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, prefix=f".{path.name}.", delete=False) as f:
        f.write(text)
        tmp = Path(f.name)
    tmp.replace(path)


def _atomic_copy(source: Path, target: Path) -> bool:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and filecmp.cmp(source, target, shallow=False):
        return False
    with tempfile.NamedTemporaryFile("wb", dir=target.parent, prefix=f".{target.name}.", delete=False) as f:
        with source.open("rb") as src:
            shutil.copyfileobj(src, f)
        tmp = Path(f.name)
    tmp.replace(target)
    return True


def _hypr_lua_string(value: str) -> str:
    return json.dumps(value)


def _apply_hyprland(theme: dict):
    hypr = theme["hyprland"]
    config = f"""hl.config({{
    misc = {{
      background_color = {_hypr_lua_string(hypr['background'])},
    }},
    general = {{
      col = {{
        active_border = {_hypr_lua_string(hypr['borderActive'])},
        inactive_border = {_hypr_lua_string(hypr['borderInactive'])},
      }},
    }},
    group = {{
      col = {{
        border_active = {_hypr_lua_string(hypr['borderActive'])},
        border_inactive = {_hypr_lua_string(hypr['borderInactive'])},
        border_locked_active = {_hypr_lua_string(hypr['borderLockedActive'])},
      }},
      groupbar = {{
        col = {{
          active = {_hypr_lua_string(hypr['groupActive'])},
          inactive = {_hypr_lua_string(hypr['groupInactive'])},
        }},
        text_color = {_hypr_lua_string(hypr['groupText'])},
        text_color_inactive = {_hypr_lua_string(hypr['groupTextInactive'])},
      }},
    }},
    decoration = {{
      shadow = {{
        color = {_hypr_lua_string(hypr['shadow'])},
      }},
    }},
  }})"""
    _run(["hyprctl", "eval", config], check=True)

    if _is_active("hyprpaper.service"):
        wallpaper = theme["wallpaper"]
        _run(["hyprctl", "hyprpaper", "preload", wallpaper], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        monitors = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True)
        for monitor in json.loads(monitors):
            name = monitor.get("name")
            if name:
                _run(["hyprctl", "hyprpaper", "wallpaper", f"{name},{wallpaper}"], stdout=subprocess.DEVNULL)


def _apply_vicinae(vicinae_theme: str):
    if not _is_active("vicinae.service"):
        return
    _run(["vicinae", "theme", "set", vicinae_theme], stdout=subprocess.DEVNULL, check=True)
    config = Path.home() / ".config/vicinae/settings.json"
    payload = {
        "$schema": "https://vicinae.com/schemas/config.json",
        "theme": {
            "light": {"name": vicinae_theme, "icon_theme": "auto"},
            "dark": {"name": vicinae_theme, "icon_theme": "auto"},
        },
        "font": {"normal": {"size": 10.5}},
        "pop_to_root_on_close": False,
        "search_files_in_root": False,
        "favicon_service": "twenty",
        "launcher_window": {
            "opacity": 0.95,
            "client_side_decorations": {
                "enabled": True,
                "rounding": 12,
                "border_width": 1,
            },
        },
    }
    _atomic_write(config, json.dumps(payload, indent=2) + "\n")


def apply_theme(theme: str, polarity: str) -> str:
    if polarity not in ("dark", "light"):
        raise ValueError(f"invalid polarity: {polarity}")

    start = time.monotonic()
    themes = json.loads(THEMES_FILE.read_text())
    selected = themes[theme][polarity]
    theme_name = selected["name"]
    theme_changed = _current_theme_name() != theme_name

    print(f"Switching to theme '{theme}' with polarity '{polarity}'...", flush=True)

    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    CHROME_POLICY_TARGET.parent.mkdir(parents=True, exist_ok=True)

    if os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
        _run(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", repr(selected["gtkColorScheme"])], check=True)
        _run(["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", "''"], check=True)

    shutil.copyfile(selected["kittyTheme"], KITTY_THEME_TARGET)
    _run(["pkill", "-USR1", "-u", os.environ.get("USER", ""), "-f", r"^kitty( |$)"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    policy_source = CHROME_POLICY_DIR / f"{theme_name}.json"
    if policy_source.exists() and _atomic_copy(policy_source, CHROME_POLICY_TARGET):
        if _run(["pgrep", "-u", os.environ.get("USER", ""), "-x", "chrome"], stdout=subprocess.DEVNULL).returncode == 0:
            subprocess.Popen(["google-chrome-stable", "--refresh-platform-policy", "--no-startup-window"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if theme_changed and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        _apply_hyprland(selected)

    _apply_vicinae(selected["vicinaeTheme"])

    _atomic_write(STATE_FILE, f"{theme_name}\n")

    if _is_active("quickshell.service"):
        _run(["qs", "--config", "cunbidun", "ipc", "--any-display", "call", "theme", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print(f"Theme switch completed in {int(time.monotonic() - start)}s", flush=True)
    return theme_name
