#!/bin/bash
CURRENT_DIR="$(pwd)"

if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install httpie \
		neovim \
		python3 \
		tmux \
		wget \
		bat \
		fpp \
		exa
	brew tap cjbassi/gotop
	brew tap caskroom/fonts
	brew cask install font-iosevka-nerd-font gotop karabiner-elements
	echo "You'll need to edit karabiner-elements to allow capslock to handle esc/ctrl"
if [ -f "/etc/arch-release" ]; then
	sudo pacman -S neovim tmux zsh httpie python3-neovim xclip
	echo "bind -t vi-copy y copy-pipe \"xclip -sel clip -i\"" >> tmux.conf
else
   	sudo add-apt-repository ppa:neovim-ppa/stable -y
	sudo apt update -y
	sudo apt-get install -y zsh tmux neovim python3 httpie python3-neovim neovim xclip
	echo "bind -t vi-copy y copy-pipe \"xclip -sel clip -i\"" >> tmux.conf
fi
pip install --user neovim
pip install --user pynvim


mkdir -p $HOME/.cache/zsh/
mkdir -p $HOME/.local/share/nvim/plugged
mkdir -p $HOME/.config/nvim/undo

curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/denysdovhan/spaceship-prompt.git $HOME/.oh-my-zsh/custom/themes/spaceship-prompt
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cp "$CURRENT_DIR/zshrc" $HOME/.zshrc
cp "$CURRENT_DIR/init.vim" $HOME/.config/nvim/
cp "$CURRENT_DIR/gitconfig" $HOME/.gitconfig
cp "$CURRENT_DIR/tmux.conf" $HOME/.tmux.conf.local
cp "$CURRENT_DIR/compinit-oh-my-zsh.zsh" /.oh-my-zsh/custom/compinit-oh-my-zsh.zsh
nvim +PlugInstall +UpdateRemotePlugins +qa
