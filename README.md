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
sh <(curl -L https://nixos.org/nix/install)
nix --extra-experimental-features nix-command --extra-experimental-features flakes  run nix-darwin -- switch --flake ~/dotfiles#macbook-m1
darwin-rebuild switch --flake ~/dotfiles#macbook-m1
```
