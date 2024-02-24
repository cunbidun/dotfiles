#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

sudo cp "$(pwd)"/configuration.nix /etc/nixos/configuration.nix 
sudo cp "$(pwd)"/flake.nix /etc/nixos/flake.nix 
