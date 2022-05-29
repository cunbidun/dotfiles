#!/bin/bash

stow common -t $HOME
rm -rf $HOME/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
