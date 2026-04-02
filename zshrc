export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR="nvim"
export BROWSER="firefox"

# Colors for ls and completions
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# Homebrew
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
else
  export PATH="/opt/homebrew/bin:$PATH"
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Completion
autoload -Uz compinit
if [ -f "$HOME/.cache/zsh/zcompdump" ]; then
  compinit -d "$HOME/.cache/zsh/zcompdump"
else
  compinit
fi
zstyle ':completion:*' rehash true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Zsh plugins
ZSH_PLUGINS="$HOME/.zsh/plugins"
source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGINS/zsh-completions/zsh-completions.plugin.zsh"
source "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh"
source "$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# Aliases
alias vim=nvim
alias ls="eza -l --color=auto --icons"
alias python='python3'
alias pip='pip3'

# Vi mode
export KEYTIMEOUT=1
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
bindkey "^[OA" history-substring-search-up
bindkey "^[OB" history-substring-search-down
bindkey -M vicmd "k" history-substring-search-up
bindkey -M vicmd "j" history-substring-search-down

# Starship prompt
eval "$(starship init zsh)"
