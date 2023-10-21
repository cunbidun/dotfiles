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
cd
yay -S pacman-contrib --needed  # extra script for pacman
yay -S neovim
yay -S zsh --needed
yay -S nautilus --needed # graphical file explorer
yay -S ueberzug --needed # TUI file explorer with image review
yay -S cargo --needed # rust
yay -S bluetuith bluez bluez-utils --needed

yay -S caprine
yay -S spotify-launcher
yay -S bazel

# =========================================================================
# Install nix 
sh <(curl -L https://nixos.org/nix/install) --daemon

# ==========================================================================
# Start services
sudo systemctl enable --now bluetooth.service
