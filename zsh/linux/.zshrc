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
plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
source $HOME/.config/alacritty/changer_autocompletion # theme changer autocompletion
source $HOME/.zshcommon

alias x="$EDITOR $HOME/.xinitrc"

unsetopt PROMPT_SP

# source /usr/share/nvm/init-nvm.sh

source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh
test -r $HOME/.dir_colors && eval $(dircolors $HOME/.dir_colors)

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

