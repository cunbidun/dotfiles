#/usr/bin/env bash

set -x

stow common -t $HOME
rm -rf $HOME/.tmux/plugins/tpm
