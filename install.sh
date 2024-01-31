#!/bin/bash
set -e
CURRENT_DIR="$(pwd)"

# Homebrew Installation
if ! command -v brew &>/dev/null; then
    echo "Installing Brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/admin/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed"
fi

echo "Brew programs next..."
brew bundle --no-lock


echo "Vim Setup..."
/opt/homebrew/bin/pip3 install --user neovim pynvim
mkdir -p "$HOME/.cache/zsh/"
mkdir -p "$HOME/.local/share/nvim/plugged"
mkdir -p "$HOME/.config/nvim/undo"
mkdir -p "$HOME/.config/nvim/colors/"

curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
echo "ZSH Setup..."

# ZSH Setup
echo "Setting up ZSH..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed"
fi

mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1

mkdir -p "$HOME/.tmux/plugins"
git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

echo "Copying configuration files..."
cp "$CURRENT_DIR/zshrc" "$HOME/.zshrc"
cp "$CURRENT_DIR/init.vim" "$HOME/.config/nvim/"
cp "$CURRENT_DIR/gitconfig" "$HOME/.gitconfig"
cp "$CURRENT_DIR/tmux.conf" "$HOME/.tmux.conf"
cp "$CURRENT_DIR/compinit-oh-my-zsh.zsh" "$HOME/.oh-my-zsh/custom/compinit-oh-my-zsh.zsh"
cp "$CURRENT_DIR/vibrantink.vim" "$HOME/.config/nvim/colors/"

nvim +PlugInstall +UpdateRemotePlugins +qa

# Rust and Cargo Installations
echo "Installing Rust and Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install ripgrep
cargo install exa
rustup component add rust-src #Needed for autcomplete on rust-analyzer

echo "Setting up iTerm2..."
mkdir -p "$HOME/.config/iterm_config"
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.config/iterm_config"
cp "$CURRENT_DIR/com.googlecode.iterm2.plist" "$HOME/.config/iterm_config"


