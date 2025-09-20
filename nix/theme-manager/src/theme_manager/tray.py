#!/usr/bin/env python3
"""
System tray icon for theme-manager daemon.
Provides a GUI interface for switching themes and polarity.
"""

import os
import sys
import json
import socket
import subprocess
import threading
import time
from tkinter import *
from tkinter import messagebox
try:
    import pystray
    from pystray import MenuItem as item
    from PIL import Image, ImageDraw
    TRAY_AVAILABLE = True
except ImportError:
    TRAY_AVAILABLE = False
    print("Warning: pystray not available, using fallback menu")

SOCKET = os.path.expanduser("~/.local/share/theme-manager/socket")

class ThemeManagerTray:
    def __init__(self):
        self.current_theme = None
        self.current_polarity = None
        self.themes = []
        self.icon = None
        self.update_status()
        
    def client_request(self, msg):
        """Send request to daemon and get response"""
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(SOCKET)
                s.sendall(msg.encode())
                resp = s.recv(4096).decode().strip()
        except (FileNotFoundError, ConnectionRefusedError):
            return None, False
        
        if resp.startswith("OK"):
            parts = resp.split(maxsplit=1)
            return parts[1] if len(parts) == 2 else "", True
        else:
            return resp, False

    def get_current_polarity(self):
        """Get current polarity from darkman"""
        try:
            result = subprocess.run(["darkman", "get"], 
                                  capture_output=True, text=True, timeout=5)
            return result.stdout.strip() if result.returncode == 0 else "dark"
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return "dark"

    def toggle_polarity(self, icon=None, item=None):
        """Toggle between dark and light mode"""
        current = self.get_current_polarity()
        new_polarity = "light" if current == "dark" else "dark"
        
        try:
            subprocess.run(["darkman", "set", new_polarity], check=True)
            self.update_status()
        except subprocess.CalledProcessError:
            if TRAY_AVAILABLE:
                messagebox.showerror("Error", f"Failed to set polarity to {new_polarity}")

    def set_theme(self, theme_name):
        """Set theme via daemon"""
        def _set():
            result, success = self.client_request(f"SET-THEME {theme_name}\n")
            if success:
                self.current_theme = theme_name
                self.update_status()
            elif TRAY_AVAILABLE:
                messagebox.showerror("Error", f"Failed to set theme: {result}")
        
        threading.Thread(target=_set, daemon=True).start()

    def update_status(self):
        """Update current theme and polarity status"""
        # Get current theme
        theme, success = self.client_request("GET-THEME\n")
        if success:
            self.current_theme = theme
        
        # Get available themes
        themes_json, success = self.client_request("LIST-THEMES\n")
        if success:
            try:
                self.themes = json.loads(themes_json)
            except json.JSONDecodeError:
                self.themes = []
        
        # Get current polarity
        self.current_polarity = self.get_current_polarity()

    def create_image(self, color="white"):
        """Create a simple icon image"""
        # Create an image with a circle
        image = Image.new('RGB', (64, 64), color=(0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        
        # Draw a circle representing theme/palette
        if color == "white":
            fill_color = (255, 255, 255)
        else:
            fill_color = (100, 100, 100)
            
        draw.ellipse([16, 16, 48, 48], fill=fill_color, outline=(200, 200, 200))
        
        # Add a small indicator for polarity
        polarity_color = (255, 255, 0) if self.current_polarity == "light" else (0, 0, 150)
        draw.ellipse([45, 15, 55, 25], fill=polarity_color)
        
        return image

    def build_menu(self):
        """Build the context menu"""
        menu_items = []
        
        # Polarity section
        current_polarity = self.current_polarity or "dark"
        polarity_text = f"Polarity: {current_polarity.title()}"
        menu_items.append(item(polarity_text, self.toggle_polarity))
        menu_items.append(item("---"))  # Separator
        
        # Theme section
        menu_items.append(item("Themes:", lambda: None, enabled=False))
        for theme in self.themes:
            checked = theme == self.current_theme
            menu_items.append(item(
                theme, 
                lambda icon, item, t=theme: self.set_theme(t),
                checked=checked
            ))
        
        menu_items.append(item("---"))  # Separator
        menu_items.append(item("Refresh", lambda icon, item: self.refresh_menu()))
        menu_items.append(item("Exit", self.quit_app))
        
        return menu_items

    def refresh_menu(self):
        """Refresh the menu with current status"""
        self.update_status()
        if self.icon:
            self.icon.menu = pystray.Menu(*self.build_menu())

    def quit_app(self, icon=None, item=None):
        """Quit the tray application"""
        if self.icon:
            self.icon.stop()

    def run_tray(self):
        """Run the system tray icon"""
        if not TRAY_AVAILABLE:
            print("Error: pystray is required for system tray functionality")
            print("Install with: pip install pystray pillow")
            return False
            
        # Create and run the tray icon
        image = self.create_image()
        menu = pystray.Menu(*self.build_menu())
        
        self.icon = pystray.Icon("theme-manager", image, "Theme Manager", menu)
        
        # Update menu periodically
        def update_loop():
            while self.icon.visible:
                time.sleep(30)  # Update every 30 seconds
                self.refresh_menu()
        
        threading.Thread(target=update_loop, daemon=True).start()
        
        try:
            self.icon.run()
        except KeyboardInterrupt:
            self.quit_app()
        
        return True

    def run_fallback_menu(self):
        """Run a simple tkinter-based menu as fallback"""
        root = Tk()
        root.title("Theme Manager")
        root.geometry("300x400")
        
        # Status frame
        status_frame = Frame(root)
        status_frame.pack(pady=10, fill='x', padx=10)
        
        Label(status_frame, text="Theme Manager", font=('Arial', 14, 'bold')).pack()
        
        self.status_label = Label(status_frame, text="Loading...")
        self.status_label.pack(pady=5)
        
        # Polarity frame
        polarity_frame = LabelFrame(root, text="Polarity", font=('Arial', 12, 'bold'))
        polarity_frame.pack(pady=10, fill='x', padx=10)
        
        Button(polarity_frame, text="Toggle Dark/Light", 
               command=self.toggle_polarity).pack(pady=5)
        
        # Theme frame
        theme_frame = LabelFrame(root, text="Themes", font=('Arial', 12, 'bold'))
        theme_frame.pack(pady=10, fill='both', expand=True, padx=10)
        
        # Scrollable theme list
        canvas = Canvas(theme_frame)
        scrollbar = Scrollbar(theme_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        self.theme_frame_inner = scrollable_frame
        
        # Control buttons
        control_frame = Frame(root)
        control_frame.pack(pady=10, fill='x', padx=10)
        
        Button(control_frame, text="Refresh", command=self.refresh_gui).pack(side='left')
        Button(control_frame, text="Exit", command=root.quit).pack(side='right')
        
        # Initial update
        self.refresh_gui()
        
        root.mainloop()

    def refresh_gui(self):
        """Refresh the GUI with current status"""
        self.update_status()
        
        # Update status
        status_text = f"Theme: {self.current_theme or 'Unknown'}\nPolarity: {self.current_polarity or 'Unknown'}"
        self.status_label.config(text=status_text)
        
        # Clear and rebuild theme buttons
        for widget in self.theme_frame_inner.winfo_children():
            widget.destroy()
        
        for theme in self.themes:
            bg_color = 'lightblue' if theme == self.current_theme else 'white'
            btn = Button(self.theme_frame_inner, text=theme, 
                        command=lambda t=theme: self.set_theme(t),
                        bg=bg_color, width=20)
            btn.pack(pady=2, padx=5, fill='x')

def main():
    """Main entry point"""
    tray_manager = ThemeManagerTray()
    
    if TRAY_AVAILABLE:
        print("Starting system tray icon...")
        tray_manager.run_tray()
    else:
        print("Starting fallback GUI...")
        tray_manager.run_fallback_menu()

if __name__ == "__main__":
    main()