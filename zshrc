export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#Setup ZSH
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="spaceship"
SPACESHIP_PROMPT_ORDER=(

  exit_code     # Exit code section
  time          # Time stamps section
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  xcode         # Xcode section
  swift         # Swift section
  golang        # Go section
  php           # PHP section
  rust          # Rust section
  haskell       # Haskell Stack section
  julia         # Julia section
  docker        # Docker section
  aws           # Amazon Web Services section
  venv          # virtualenv section
  conda         # conda virtualenv section
  pyenv         # Pyenv section
  dotnet        # .NET section
  ember         # Ember.js section
  kubecontext   # Kubectl context section
  terraform     # Terraform workspace section
  exec_time     # Execution time
  line_sep      # Line break
  battery       # Battery level and status
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  char          # Prompt character
  )
SPACESHIP_EXIT_CODE_SHOW="true"
SPACESHIP_PROMPT_ADD_NEWLINE="true"
SPACESHIP_HOST_SHOW_FULL="true"
SPACESHIP_HOST_COLOR="red"
SPACESHIP_CHAR_SYMBOL="\ue62e"
SPACESHIP_CHAR_SUFFIX=("  ")
SPACESHIP_EXIT_CODE_SUFFIX="\n"
SPACESHIP_CHAR_COLOR_SUCCESS="green"
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW="true"
#SPACESHIP_CHAR_SYMBOL_SECONDARY="\ue62d"
alias ls="colorls --light --sort-dirs"
alias lc="colorls --tree --light"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions docker docker-compose heroku colored-man-pages command-not-found aws common-aliases encode64 jsontools sudo gitfast )
source $ZSH/oh-my-zsh.sh

#Persistent rehash
zstyle ':completion:*' rehash true

export BROWSER="firefox"
export EDITOR="vim"

#Setup Golang
export GOPATH=$HOME/workspace/go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

#Add python binaries such as awscli to the path
export PATH="/usr/local/opt/python/libexec/bin:$PATH"

alias vim=nvim
function git() { hub $@; }
