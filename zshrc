export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="nvim"
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
  package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  golang        # Go section
  php           # PHP section
  rust          # Rust section
  haskell       # Haskell Stack section
  docker        # Docker section
  venv          # virtualenv section
  conda         # conda virtualenv section
  terraform     # Terraform workspace section
  exec_time     # Execution time
  line_sep      # Line break
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

plugins=(git colored-man-pages history-substring-search zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

#Persistent rehash
zstyle ':completion:*' rehash true

alias vim=nvim
alias ls="eza -l"
alias python='python3'
alias pip='pip3'
export KEYTIMEOUT=1 #Required for vi-mode notification lag
bindkey "^[OA" up-line-or-beginning-search #Add searching when using vi-mode
bindkey "^[OB" down-line-or-beginning-search
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  export PATH="/opt/homebrew/bin:$PATH"
fi
