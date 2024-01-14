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
# Install system packages
cd
yay -S pacman-contrib --needed # extra script for pacman
yay -S neovim
yay -S zsh --needed
yay -S bluetuith bluez bluez-utils --needed # bluetooth
yay -S pipewire pipewire-pulse pulsemixer pipewire-media-session pactl --needed
yay -S nautilus sushi file-roller --needed

yay -S caprine                                        # ibus is not working with nix yet
yay -S quickemu --needed                              # ibus is not working with nix yet
yay -S swaylock-effects-git--needed swayidle --needed # need pam module

# =========================================================================
# Install nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# ==========================================================================
# Start services
sudo systemctl enable --now bluetooth.service

# ==========================================================================
# obs installation
yay -S vulkan-amdgpu-pro vulkan-radeon
yay -S obs-studio fmpeg-amd-full ffmpeg-amd-full obs-streamfx-git --noconfirm --needed
