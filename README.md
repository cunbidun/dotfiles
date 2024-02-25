# Duy Pham's dotfiles repo

## Screenshot

![alt text](./images/dwm-desktop.png "Screenshot")

## NixOS

```bash
nix flake update ~/dotfiles
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
# Fix broken symlink
nix-store --repair --verify --check-contents
# Clear old symlink and version
nix-collect-garbage -d
```
