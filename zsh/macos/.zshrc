export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"

# nord color FZF 
# export FZF_DEFAULT_OPTS="
#   --color fg:#D8DEE9,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C,pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
#   --preview-window sharp
# "

# tokyo night color
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
# 	--color=fg:#c0caf5,hl:#bb9af7
# 	--color=fg+:#c0caf5,hl+:#7dcfff
# 	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff 
# 	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'

export BAT_STYLE="plain"
export BAT_THEME="Nord"
export BAT_OPTS="--color always"

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

plugins=(git zsh-syntax-highlighting docker docker-compose)

source $ZSH/oh-my-zsh.sh
source $HOME/.zshcommon

# load common alias after loading oh-my-zsh
source $HOME/.config/alacritty/changer_autocompletion # theme changer autocompletion

alias cdnote="cd '/Users/cunbidun/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents'"

[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
# test -r $HOME/.dir_colors && eval $(gdircolors $HOME/.dir_colors)

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
# export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

