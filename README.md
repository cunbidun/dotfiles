# Duy Pham's dotfiles repo

## Screenshot

![alt text](./images/dwm-desktop.png "Screenshot")

## home-manager
```bash
# update nix
nix --extra-experimental-features "flakes" --extra-experimental-features "nix-command" flake update ~/dotfiles
# rebuild
home-manager --extra-experimental-features "flakes" --extra-experimental-features "nix-command" switch --flake ~/dotfiles --impure
```
