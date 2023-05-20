export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"

export BAT_STYLE="plain"
export BAT_THEME="Nord"
export BAT_OPTS="--color always"

source $HOME/.zshenv
export PATH=$PATH:$HOME/.local/share/flutter/bin
export TERMINAL='iterm2'

# set words split for zsh
# why? for git integration to work correctly
# see more: https://stackoverflow.com/questions/23157613/how-to-iterate-through-string-one-word-at-a-time-in-zsh
setopt shwordsplit

# git stuff
source $HOME/.git-prompt.sh
setopt PROMPT_SUBST ; PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '

# prompt
fpath=($HOME/.zprompts/ $fpath)
autoload -Uz promptinit
promptinit
prompt igloo

DISABLE_UPDATE_PROMPT="true"

# update frequency
export UPDATE_ZSH_DAYS=3

# history timestamp
HIST_STAMPS="mm/dd/yyyy"

# plugins=(git zsh-syntax-highlighting docker docker-compose)
plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
source $HOME/.zshcommon

alias cdnote="cd '/Users/cunbidun/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents'"

[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/cunbidun/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/cunbidun/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/cunbidun/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/cunbidun/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
