# adding important bin to bash
export PATH=$PATH:$HOME/.scripts/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin

if [ "$(uname)" = "Darwin" ]; then
  export PATH=/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH
fi

[ -d "/snap/bin" ] && export PATH=$PATH:/snap/bin
