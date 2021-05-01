export ZSH="/home/cunbidun/.oh-my-zsh"
export TERM="xterm-256color"
export FZF_DEFAULT_OPTS='
  --color fg:#D8DEE9,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C,pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
'

# set words split for zsh
# why? for git integration to work correctly
# see more: https://stackoverflow.com/questions/23157613/how-to-iterate-through-string-one-word-at-a-time-in-zsh
setopt shwordsplit

# git stuff
source ~/.git-prompt.sh
setopt PROMPT_SUBST ; PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '

fpath=(/home/cunbidun/.zprompts/ $fpath)
autoload -Uz promptinit
promptinit
prompt igloo

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
 export UPDATE_ZSH_DAYS=3

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"


plugins=(git docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

alias zshconfig="nvim ~/.zshrc"
alias CP="~/competitive_programming/"
alias b="~/.script/brightness.sh"
alias r="ranger"

# Umass
alias 320="~/Documents/Umass/Spring2021/COMPSCI\ 320"
alias 445="~/Documents/Umass/Spring2021/COMPSCI\ 445"
alias 446="~/Documents/Umass/Spring2021/COMPSCI\ 446"
alias 466="~/Documents/Umass/Spring2021/COMPSCI\ 466"
alias 497="~/Documents/Umass/Spring2021/COMPSCI\ 497S"
alias cpf='f() { xclip -sel clip < $1 }; f'

alias ls="exa -la"

unsetopt PROMPT_SP

export PATH="/home/cunbidun/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh

test -r ~/.dir_colors && eval $(dircolors ~/.dir_colors)

# colorscript -e 19
# source /usr/share/nvm/init-nvm.sh


