# Nix on Raspberry Pi 5

- burn a img with ssh key root to a usb stick, then plub it into the Raspberry Pi 5. temporary remove the sd card.
boot the Raspberry Pi 5 with the usb stick. 

- Make sure 
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon --yes
```

- Add the following lines to `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes

trusted-users = root 
extra-substituters = https://nixos-raspberrypi.cachix.org
extra-trusted-public-keys = nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI=
```
- then restart the nix daemon and add paths to the environment:
```bash
systemctl restart nix-daemon  

echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /etc/bash.bashrc
echo 'source /root/.nix-profile/etc/profile.d/nix.sh' >> /etc/bash.bashrc
echo 'PATH="/root/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/environment
```

- install the NixOS installation tools:
```
nix-env -iA nixpkgs.nixos-install-tools
```
- insert the sd card
- on a remote host run
```bash
nix run github:nix-community/nixos-anywhere --  --flake .#rpi5 --build-on remote --phases disko root@192.168.1.165
nix run github:nix-community/nixos-anywhere --  --flake .#rpi5 --build-on remote --phases install  root@192.168.1.165
```