export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="vim"
export BROWSER="firefox"

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
  # Amazon Web Services section
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
SPACESHIP_TIME_COLOR="green"
SPACESHIP_TIME_SHOW="true"
SPACESHIP_TIME_FORMAT="%W-%*"

plugins=(git zsh-syntax-highlighting zsh-autosuggestions docker docker-compose heroku colored-man-pages command-not-found  encode64 jsontools sudo httpie urltools)
source $ZSH/oh-my-zsh.sh

#Persistent rehash
zstyle ':completion:*' rehash true

alias vim=nvim
alias anaconda="source ~/.conda.zshrc"
alias ls="exa -l"
alias cat=bat
alias htop=gotop
alias curl=http

