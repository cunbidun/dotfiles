sudo nix-channel --add https://nixos.org/channels/nixos-unstable
sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

sudo nix-channel --update
sudo nixos-rebuild switch --upgrade
nix-shell '<home-manager>' -A install
