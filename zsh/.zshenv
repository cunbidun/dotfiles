# adding important bin to bash
if [ "$(uname)" = "Darwin" ]; then
  export PATH=/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH
fi

export PATH=$PATH:$HOME/.scripts/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin

[ -d "/snap/bin" ] && export PATH=$PATH:/snap/bin
