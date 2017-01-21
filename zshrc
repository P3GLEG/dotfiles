export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="xiong-chiamiov"
plugins=(git zsh-syntax-highlighting docker docker-compose heroku colrize\
    colored-man-pages command-not-found aws common-aliases encode64 jsontools sudo ccze)
source $ZSH/oh-my-zsh.sh

##Dirstack dirs -v
DIRSTACKFILE="$HOME/.cache/zsh/dirs"
if [[ -f $DIRSTACKFILE ]] && [[ $#dirstack -eq 0 ]]; then
  dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
  [[ -d $dirstack[1] ]] && cd $dirstack[1]
fi
chpwd() {
  print -l $PWD ${(u)dirstack} >$DIRSTACKFILE
}
DIRSTACKSIZE=20
setopt AUTO_PUSHD PUSHD_SILENT PUSHD_TO_HOME
## Remove duplicate entries
setopt PUSHD_IGNORE_DUPS
## This reverts the +/- operators.
setopt PUSHD_MINUS

#Persistent rehash
zstyle ':completion:*' rehash true

export BROWSER="chromium"
export EDITOR="vim"


alias nuke-docker='docker rm -v $(docker ps -a -q -f status=exited) && docker rmi $(docker images -f "dangling=true" -q)'
