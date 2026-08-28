#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting dotfiles setup from $CURRENT_DIR"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  ln -snf "$src" "$dest"
  echo "Linked: $dest -> $src"
}

clone_or_update() {
  local repo="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth=1 "$repo" "$dest"
  fi
}

# 1) Homebrew + packages
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to shell env
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    if [ -n "${HOME:-}" ]; then
      brew shellenv >> "$HOME/.zprofile"
    fi
  fi
else
  echo "Homebrew already installed"
  eval "$(brew shellenv)" || true
fi

echo "Installing Homebrew packages from Brewfile..."
brew bundle  --file "$CURRENT_DIR/Brewfile"

# 2) Neovim
echo "Configuring Neovim..."
mkdir -p "$HOME/.config"
link "$CURRENT_DIR/nvim" "$HOME/.config/nvim"
mkdir -p "$HOME/.config/nvim/undo" "$HOME/.cache/zsh"

# Bootstrap/Sync lazy.nvim plugins (non-fatal if nvim missing)
if command -v nvim >/dev/null 2>&1; then
  nvim --headless "+Lazy! sync" +qa || true
fi

# Python provider (optional)
if command -v pip3 >/dev/null 2>&1; then
  pip3 install --user --upgrade pynvim >/dev/null 2>&1 || true
fi

# 3) Zsh plugins (no framework)
echo "Setting up Zsh plugins..."
ZSH_PLUGINS="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGINS"

clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-completions "$ZSH_PLUGINS/zsh-completions"
clone_or_update https://github.com/zsh-users/zsh-history-substring-search "$ZSH_PLUGINS/zsh-history-substring-search"
clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_PLUGINS/fast-syntax-highlighting"


# 5) Symlink dotfiles
echo "Linking dotfiles..."
link "$CURRENT_DIR/zshrc" "$HOME/.zshrc"
link "$CURRENT_DIR/gitconfig" "$HOME/.gitconfig"
link "$CURRENT_DIR/starship.toml" "$HOME/.config/starship.toml"

# 6) Ghostty
echo "Configuring Ghostty..."
# Link the FILE, not the directory. Ghostty creates ~/.config/ghostty on
# first run, and `ln -snf src dir` on an existing REAL directory silently
# links INSIDE it (~/.config/ghostty/ghostty) instead of replacing it -- -n
# only guards a symlink-to-directory. That left the real config untouched
# and the dotfiles one never in effect.
mkdir -p "$HOME/.config/ghostty"
if [ -f "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
  cp "$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backed up existing ghostty config"
fi
# Clean up the nested link left by the previous directory-linking behaviour.
[ -L "$HOME/.config/ghostty/ghostty" ] && rm -f "$HOME/.config/ghostty/ghostty"
link "$CURRENT_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# 7) cmux (agent workspace manager)
echo "Configuring cmux..."
mkdir -p "$HOME/.config/cmux" "$HOME/.claude/hooks" "$HOME/.claude/agent-state" "$HOME/.cache/cmux"

# Back up an existing real cmux.json before replacing it with the symlink.
if [ -f "$HOME/.config/cmux/cmux.json" ] && [ ! -L "$HOME/.config/cmux/cmux.json" ]; then
  cp "$HOME/.config/cmux/cmux.json" "$HOME/.config/cmux/cmux.json.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backed up existing cmux.json"
fi
link "$CURRENT_DIR/cmux/cmux.json" "$HOME/.config/cmux/cmux.json"

# Claude Code lifecycle hook + helpers live under ~/.claude/hooks so the
# paths in settings.json and the launchd plist stay stable.
link "$CURRENT_DIR/cmux/hooks/cmux-agent-status.sh" "$HOME/.claude/hooks/cmux-agent-status.sh"
link "$CURRENT_DIR/cmux/bin/cmux-stall-watch.sh"    "$HOME/.claude/hooks/cmux-stall-watch.sh"
link "$CURRENT_DIR/cmux/bin/cmux-notify-route.sh"   "$HOME/.claude/hooks/cmux-notify-route.sh"

# Task spawner + its per-repo badge map. cmux.json references new-task.sh by
# the ~/.config/cmux path, so the symlink location is load-bearing.
link "$CURRENT_DIR/cmux/bin/new-task.sh"     "$HOME/.config/cmux/new-task.sh"
link "$CURRENT_DIR/cmux/repo-badges.tsv"     "$HOME/.config/cmux/repo-badges.tsv"

# Workspace-hygiene rules, loaded by Claude Code as a global rule file.
mkdir -p "$HOME/.claude/rules"
link "$CURRENT_DIR/cmux/rules/cmux-workspace-hygiene.md" "$HOME/.claude/rules/cmux-workspace-hygiene.md"

# Merge hook entries into ~/.claude/settings.json (not symlinked: it holds
# personal permissions/model/MCP state). Idempotent.
if [ -f "$HOME/.claude/settings.json" ]; then
  python3 "$CURRENT_DIR/cmux/bin/install-claude-hooks.py" || true
else
  echo "Skipping Claude hook wiring: ~/.claude/settings.json not found"
fi

# Stall watchdog as a launchd agent. Set WITH_CMUX_WATCHDOG=0 to skip.
if [ "${WITH_CMUX_WATCHDOG:-1}" = "1" ]; then
  CMUX_PLIST="$HOME/Library/LaunchAgents/com.pegleg.cmux-stall-watch.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s|__HOME__|$HOME|g" "$CURRENT_DIR/cmux/launchd/com.pegleg.cmux-stall-watch.plist" > "$CMUX_PLIST"
  launchctl bootout "gui/$(id -u)/com.pegleg.cmux-stall-watch" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$CMUX_PLIST" 2>/dev/null \
    && echo "Loaded cmux stall watchdog" \
    || echo "Could not load stall watchdog (load it later with: launchctl bootstrap gui/$(id -u) $CMUX_PLIST)"
fi

# Apply without restarting cmux (no-op if cmux is not running).
if command -v cmux >/dev/null 2>&1 || [ -x /Applications/cmux.app/Contents/Resources/bin/cmux ]; then
  "${CMUX_BIN:-/Applications/cmux.app/Contents/Resources/bin/cmux}" reload-config >/dev/null 2>&1 \
    && echo "Reloaded cmux config" || true
fi

# 8) Optional Rust toolchain
if [ "${WITH_RUST:-0}" = "1" ]; then
  echo "Installing Rust toolchain (WITH_RUST=1)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || true
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi
  command -v cargo >/dev/null 2>&1 && rustup component add rust-src || true
fi

echo "Done. Open a new terminal session to load changes."
