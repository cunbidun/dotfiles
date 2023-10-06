#!/bin/bash

set -e

echo "Installing deps"

yay -S stow --needed # for symlink configs
yay -S ddcutil --needed # for controlling back-light
yay -S alacritty --needed # dwm terminal of choice 
yay -S imlib2 --needed # for showing workspace screenshot
yay -S libxft --needed # for fonts
yay -S main --needed # for screenshot 
yay -S xorg-server xorg-apps xorg-xinit xclip xdotool --needed # xorg
yay -S arandr --needed # controlling xrandr
yay -S feh --needed # set wallpaper
yay -S dunst --needed # notification daemon
yay -S pamixer pulsemixer --needed # sound control
yay -S ibus-daemon ibus-bamboo --needed # VNese keyboard
yay -S picom-git --needed # compositor
yay -S calcurse --needed # tui calendar
yay -S xf86-input-wacom --needed # for wacom
