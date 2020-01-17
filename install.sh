#!/bin/bash
if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install httpie \
		neovim \
		python3 \
		tmux \
		wget
	brew tap caskroom/fonts
	brew cask install font-iosevka-nerd-font
else
   	sudo add-apt-repository ppa:neovim-ppa/stable -y
	sudo apt update -y
	sudo apt-get install -y zsh tmux neovim python3 httpie python3-neovim neovim
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
git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux

cp $(pwd)/zshrc $HOME/.zshrc
cp $(pwd)/init.vim $HOME/.config/nvim/
cp $(pwd)/gitconfig $HOME/.gitconfig
cp $(pwd)/tmux.conf $HOME/.tmux.conf.local
nvim +PlugInstall +UpdateRemotePlugins +qa
