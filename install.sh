#!/bin/bash
if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install httpie \
		hub \
		neovim \
		python3 \
		tmux \
		wget
	brew tap caskroom/fonts
	brew cask install font-hack-nerd-font
else
	sudo apt-get install -y zsh tmux fonts-hack-ttf neovim python3
fi
pip3 install --user pynvim
mkdir -p $HOME/.cache/zsh/
mkdir -p $HOME/.local/share/nvim/plugged
mkdir -p $HOME/.config/nvim/undo
curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g' | sed 's:chsh -s .*$::g')"
curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/denysdovhan/spaceship-prompt.git $HOME/.oh-my-zsh/custom/themes/spaceship-prompt
cp $(pwd)/zshrc $HOME/.zshrc
cp $(pwd)/init.vim $HOME/.config/nvim/
cp $(pwd)/gitconfig $HOME/.gitconfig
vim +'PlugInstall --sync' +qa
wget -O /usr/local/bin/imgcat https://www.iterm2.com/utilities/imgcat && sudo chmod +x /usr/local/bin/imgcat
sudo gem install colorls -n /usr/local/bin/
sudo chsh -s $USER /bin/zsh
