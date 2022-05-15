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

alias zshconfig="$MY_EDITOR $HOME/.zshrc"

alias CP="$HOME/competitive_programming/"
alias b="set_brightness"
alias r="ranger"
alias s="source $HOME/.zshrc"
alias x="$MY_EDITOR $HOME/.xinitrc"

alias bd="$HOME/dotfiles/scripts/.scripts/bin"
alias cpf='f() { xclip -sel clip < $1 }; f'

alias ls="exa -la"

# alias task="task ls"
alias ut="task +umass"
alias ct="task +cp"
alias lt="task +linux"
alias tt="task +todo"

unsetopt PROMPT_SP

eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# colorscript -e 19
# source /usr/share/nvm/init-nvm.sh

if [ "$(uname)" = "Darwin" ]; then
  [ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
  test -r $HOME/.dir_colors && eval $(gdircolors $HOME/.dir_colors)
else
  source /usr/share/fzf/completion.zsh
  source /usr/share/fzf/key-bindings.zsh
  test -r $HOME/.dir_colors && eval $(dircolors $HOME/.dir_colors)
fi

