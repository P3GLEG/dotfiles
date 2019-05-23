#!/bin/bash
if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install python3 wget tmux httpie
	brew install neovim
	brew tap caskroom/fonts
	brew cask install font-hack-nerd-font
else
	sudo apt-get install zsh tmux fonts-hack-ttf vim xclip
fi

git clone git://github.com/amix/vimrc.git ~/.vim_runtime
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/ekalinin/Dockerfile.vim.git ~/.vim_runtime/sources_non_forked/dockerautocomplete
cp $(pwd)/zshrc ~/.zshrc
cp $(pwd)/tmux.conf ~/.tmux.conf
cp $(pwd)/vimrc~/.vimrc
git clone https://github.com/denysdovhan/spaceship-prompt.git ~/.oh-my-zsh/custom/themes/spaceship-prompt
ln -s ~/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme ~/.oh-my-zsh/custom/themes/spaceship.zsh-theme
mkdir -p $HOME/.cache/zsh/
sudo mkdir -p /root/.cache/zsh/
sudo chsh -s $USER /bin/zsh
sudo wget -O /usr/local/bin/imgcat https://www.iterm2.com/utilities/imgcat && sudo chmod +x /usr/local/bin/imgcat
echo "alias vim=nvim" >> ~/.zshrc
sudo gem install colorls -n /usr/local/bin/
