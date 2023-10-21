#!/bin/bash

set -ex

# =======================================================================
cd /tmp
echo "Installing yay"
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# =======================================================================
cd /tmp
echo "Installing 1pass"
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
git clone https://aur.archlinux.org/1password.git
cd 1password
makepkg -si

# =======================================================================
cd
yay -S pacman-contrib --needed  # extra script for pacman
yay -S zsh --needed
yay -S xcursor-osx-elcap mcmojave-cursors --needed # MacOS cursor theme
yay -S brave-bin --needed # browser
yay -S neovim --needed # text editor
yay -S tmux tmuxinator --needed # tmux
yay -S nautilus --needed # graphical file explorer
yay -S ranger ueberzug --needed # TUI file explorer with image review
yay -S wget --needed
yay -S obsidian --needed # note application
yay -S cargo --needed # rust
yay -S lxappearance papirus-folders-nordic --needed # gtk themes
yay -S ncdu --needed # check disk usage 
yay -S visual-studio-code-bin --needed
yay -S glxinfo hwinfoc --needed  # hardware info
yay -S bluetuith bluez bluez-utils --needed


yay -S shellcheck
yay -S signal-desktop
yay -S caprine
yay -S spotify-launcher
yay -S bazel
yay -S google-chrome
yay -S espanso

# =========================================================================
# Install nix 
sh <(curl -L https://nixos.org/nix/install) --daemon

# ==========================================================================
# Start services
sudo systemctl enable --now bluetooth.service
