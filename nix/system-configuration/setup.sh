#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

sudo ln -sf "$(pwd)"/configuration.nix /etc/nixos/configuration.nix 
sudo ln -sf "$(pwd)"/flake.nix /etc/nixos/flake.nix 
# sudo ln -sf "$(pwd)"/hardware-configuration.nix /etc/nixos/hardware-configuration.nix 
