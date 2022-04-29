export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"
export FZF_DEFAULT_OPTS="
  --color fg:#D8DEE9,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C,pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
  --preview-window sharp
"
export BAT_STYLE="plain"
export BAT_THEME="Nord"
export BAT_OPTS="--color always"
export CPCLI_PATH="$HOME/competitive_programming/cpcli/"

source $HOME/.zshenv

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

# plugins=(git timewarrior zsh-autosuggestions zsh-syntax-highlighting)
# plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
plugins=(git zsh-syntax-highlighting docker docker-compose)

source $ZSH/oh-my-zsh.sh
source $HOME/.zshcommon

# load common alias after loading oh-my-zsh
source $HOME/.config/alacritty/changer_autocompletion # theme changer autocompletion

# User configuration
export LANG=en_US.UTF-8

MY_EDITOR='lvim'
export TERMINAL='alacritty'
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR=$MY_EDITOR
  export VISUAL=$MY_EDITOR
fi

alias note="cd '/Users/cunbidun/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents'"

unsetopt PROMPT_SP

[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
test -r $HOME/.dir_colors && eval $(gdircolors $HOME/.dir_colors)

gitpush() {
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  CURRENT_BRANCH="${1:-$CURRENT_BRANCH}"
  git push origin --delete $CURRENT_BRANCH && git push --set-upstream origin $CURRENT_BRANCH
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/cunbidun/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/cunbidun/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/cunbidun/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/cunbidun/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
