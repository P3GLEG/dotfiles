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
link "$CURRENT_DIR/ghostty" "$HOME/.config/ghostty"

# 7) Optional Rust toolchain
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
