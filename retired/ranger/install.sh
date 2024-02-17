#/usr/bin/env bash

# symlink config
stow common --no-folding -t "$HOME"

# Install ranger_devicons
git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
