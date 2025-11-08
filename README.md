# Duy Pham's dotfiles repo

## Screenshot

![alt text](./images/dwm-desktop.png "Screenshot")

## Nix

### NixOS

#### Bootstrap

To bootstrap NixOS with my dotfiles, follow these steps:
1. Clone the repository to ~/dotfiles
2. Change the username defined configuration.nix

#### To update the system
1. Run `nix flake update ~/dotfiles`
2. Run `~/dotfiles/scripts/switch.sh`

#### Cleanup old generations
```bash
sudo nix-collect-garbage --delete-older-than 7d
sudo nix-store --optimise
```

### MacOS

#### Bootstrap
To bootstrap nix on MacOS with my dotfiles, follow these steps:
1. Clone the repository to ~/dotfiles
2. Change the username defined configuration.nix
3. Install Nix on MacOS `sh <(curl -L https://nixos.org/nix/install)`
4. Run `nix flake update ~/dotfiles`
5. Run `nix --extra-experimental-features nix-command --extra-experimental-features flakes  run nix-darwin -- switch --flake ~/dotfiles#macbook-m1`

#### To update the system
After bootstrapping, you can update your system by running `~/dotfiles/scripts/switch.sh`

## Docs
- [Signal bridge setup](docs/signal-bridge.md)
