#!/usr/bin/env python3
"""Clean strict system tray implementation for theme-manager."""

import os
import sys
import json
import socket
import subprocess
import threading
import time
import logging

import pystray
from pystray import MenuItem as Item
from PIL import Image, ImageDraw, ImageFont

SOCKET = os.path.expanduser("~/.local/share/theme-manager/socket")
DARK_ICON = ""
LIGHT_ICON = ""
FONT_NAME = "SFMono Nerd Font"
FONT_ENV = "THEME_MANAGER_FONT"

# ------------- logging setup ------------- #
_LOG_LEVEL = os.environ.get("THEME_TRAY_LOG", "INFO").upper()
logger = logging.getLogger("theme-tray")
if not logger.handlers:
    handler_out = logging.StreamHandler(stream=sys.stdout)
    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    handler_out.setFormatter(formatter)
    logger.addHandler(handler_out)
    # Errors will still go to stdout handler; add stderr for >=ERROR if desired
    handler_err = logging.StreamHandler(stream=sys.stderr)
    handler_err.setLevel(logging.ERROR)
    handler_err.setFormatter(formatter)
    logger.addHandler(handler_err)
    try:
        logger.setLevel(getattr(logging, _LOG_LEVEL))
    except AttributeError:
        logger.setLevel(logging.INFO)
logger.propagate = False


class ThemeManagerTray:
    def __init__(self) -> None:
        self.current_theme: str | None = None
        self.current_polarity: str | None = None
        self.themes: list[str] = []
        self.icon: pystray.Icon | None = None
        self._font: ImageFont.FreeTypeFont | ImageFont.ImageFont | None = None
        self.update_status()

    # ------------- font resolution ------------- #
    def _load_font(self, size: int = 48):
        if self._font is not None:
            return self._font
        # explicit override path
        override = os.environ.get(FONT_ENV)
        if override and os.path.isfile(override):
            try:
                self._font = ImageFont.truetype(override, size)
                return self._font
            except Exception:
                pass

        # fc-match lookup
        try:
            result = subprocess.run([
                "fc-match", "-f", "%{file}\n", FONT_NAME
            ], capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                path = result.stdout.strip().splitlines()[0]
                if path and os.path.isfile(path):
                    try:
                        self._font = ImageFont.truetype(path, size)
                        return self._font
                    except Exception:
                        pass
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass

        try:
            self._font = ImageFont.load_default()
        except Exception:
            self._font = None
        return self._font

    # ------------- daemon interaction ------------- #
    def client_request(self, msg: str):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCKET)
                s.sendall(msg.encode())
                resp = s.recv(4096).decode().strip()
        except (FileNotFoundError, ConnectionRefusedError):
            return None, False
        if resp.startswith("OK"):
            parts = resp.split(maxsplit=1)
            return (parts[1] if len(parts) == 2 else ""), True
        return resp, False

    def get_current_polarity(self) -> str:
        pol, ok = self.client_request("GET-POLARITY\n")
        return pol if ok and pol else "dark"

    def toggle_polarity(self, *_):
        new, ok = self.client_request("TOGGLE-POLARITY\n")
        if ok:
            self.current_polarity = new
            self.refresh_menu()
        else:
            logger.error(f"Failed to toggle polarity: {new}")

    def set_theme(self, theme: str):
        def _set():
            result, ok = self.client_request(f"SET-THEME {theme}\n")
            if ok:
                self.current_theme = theme
                self.refresh_menu()
            else:
                logger.error(f"Failed to set theme: {result}")
        threading.Thread(target=_set, daemon=True).start()

    def update_status(self):
        theme, ok = self.client_request("GET-THEME\n")
        if ok:
            self.current_theme = theme
        themes_json, ok = self.client_request("LIST-THEMES\n")
        if ok:
            try:
                self.themes = json.loads(themes_json)
            except json.JSONDecodeError:
                self.themes = []
        self.current_polarity = self.get_current_polarity()

    # ------------- tray presentation ------------- #
    def create_image(self) -> Image.Image:
        size = 64
        fg = (255, 255, 255, 230)
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        font = self._load_font(size=60) or ImageFont.load_default()
        text = LIGHT_ICON if self.current_polarity == "light" else DARK_ICON
        if (isinstance(font, ImageFont.ImageFont) and any(ord(c) > 127 for c in text)):
            text = "TM"
        draw.text((0, 0), text, font=font, fill=fg)

        return img

    def build_menu(self):
        items = []
        pol = self.current_polarity or "dark"
        items.append(Item(f"Polarity: {pol.title()}", self.toggle_polarity, default=True))
        items.append(pystray.Menu.SEPARATOR)
        items.append(Item("Themes:", lambda: None, enabled=False))
        for t in self.themes:
            def mk(theme_name):
                return lambda *_: self.set_theme(theme_name)
            items.append(Item(t, mk(t), checked=lambda i, theme=t: theme == self.current_theme))
        items.append(pystray.Menu.SEPARATOR)
        items.append(Item("Refresh", lambda *_: self.refresh_menu()))
        items.append(Item("Exit", self.quit_app))
        return items

    def refresh_menu(self):
        self.update_status()
        if self.icon:
            self.icon.icon = self.create_image()
            self.icon.menu = pystray.Menu(*self.build_menu())

    def quit_app(self, *_):
        if self.icon:
            self.icon.stop()

    def run(self):
        self.update_status()
        logger.info("Starting tray icon")
        self.icon = pystray.Icon("theme-manager", self.create_image(), "Theme Manager", pystray.Menu(*self.build_menu()))
        try:
            self.icon.run()
        except KeyboardInterrupt:
            logger.info("KeyboardInterrupt received; quitting tray")
            self.quit_app()
        finally:
            logger.info("Tray icon stopped")
