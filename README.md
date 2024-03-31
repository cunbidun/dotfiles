# Duy Pham's dotfiles repo

## Screenshot

![alt text](./images/dwm-desktop.png "Screenshot")

## Nix

### NixOS

```bash
nix flake update ~/dotfiles
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
nix-store --repair --verify --check-contents#  Fix broken symlink
nix-collect-garbage -d
```

### MacOS

```nix
# installing nix on MacOS
sh <(curl -L https://nixos.org/nix/install)
# Initial switch to the nix-darwin flake
nix --extra-experimental-features nix-command --extra-experimental-features flakes  run nix-darwin -- switch --flake ~/dotfiles#macbook-m1
# Subsequent switches
darwin-rebuild switch --flake ~/dotfiles#macbook-m1
```
