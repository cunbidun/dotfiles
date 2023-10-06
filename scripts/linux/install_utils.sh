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
yay -S neofetch --needed # for fun :)
yay -S exa --needed # ls replacement
yay -S fzf --needed # for fzf
yay -S xcursor-osx-elcap --needed # MacOS cursor theme
yay -S brave-bin --needed # browser
yay -S neovim --needed # text editor
yay -S tmux tmuxinator --needed # tmux
yay -S nautilus --needed # graphical file explorer
yay -S ranger --needed # TUI file explorer
yay -S wget --needed
yay -S obsidian --needed # note application
yay -S cargo --needed # rust
yay -S lxappearance papirus-folders-nordic # gtk themes
yay -S bat # cat replacement


yay -S shellcheck
yay -S signal-desktop
yay -S caprine
yay -S spotify-launcher
yay -S bazel
yay -S google-chrome
yay -S espanso
