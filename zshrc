export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="spaceship"
SPACESHIP_USER_SHOW="false"
SPACESHIP_PROMPT_ADD_NEWLINE="true"
SPACESHIP_CHAR_SYMBOL=" \uf9df"
SPACESHIP_CHAR_PREFIX="\uf302"
SPACESHIP_CHAR_SUFFIX=(" ")
SPACESHIP_CHAR_COLOR_SUCCESS="yellow"
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW="true"
alias ls="colorls --light --sort-dirs"
alias lc="colorls --tree --light"
plugins=(git zsh-syntax-highlighting docker docker-compose heroku \
    colored-man-pages command-not-found aws common-aliases encode64 jsontools sudo )
source $ZSH/oh-my-zsh.sh

#Persistent rehash
zstyle ':completion:*' rehash true

export BROWSER="firefox"
export EDITOR="vim"

alias nuke-docker='docker rm -v $(docker ps -a -q -f status=exited) && docker rmi $(docker images -f "dangling=true" -q)'

export GOPATH=$HOME/workspace/go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

export PATH="/usr/local/opt/python/libexec/bin:$PATH"
alias vim=nvim
__conda_setup="$(CONDA_REPORT_ERRORS=false '/anaconda3/bin/conda' shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

alias vim=nvim
