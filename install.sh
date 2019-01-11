#!/bin/bash
if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install python3 wget tmux
    brew install neovim
elif [ -f "/etc/arch-release" ]; then
	sudo pacman -S zsh tmux ttf-hack powerline python-pip powerline-common wget
else
	sudo apt-get install zsh tmux fonts-hack-ttf vim xclip
	#Created at terminal.sexy
	./terminaltheme.sh
fi

git clone git://github.com/amix/vimrc.git ~/.vim_runtime
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/ekalinin/Dockerfile.vim.git ~/.vim_runtime/sources_non_forked/dockerautocomplete


#Symlink config files
if [ "$EUID" -ne 0 ]; then
    sudo ln -sf ~/.oh-my-zsh /root/.oh-my-zsh
    sudo ln -sf ~/.vim_runtime /root/.vim_runtime
fi

ln -sf $(pwd)/zshrc ~/.zshrc
ln -sf $(pwd)/vimrc ~/.vimrc
ln -sf $(pwd)/tmux.conf ~/.tmux.conf


mkdir -p ~/.cache/zsh/
sudo mkdir -p /root/.cache/zsh/
chsh -s /bin/zsh
sudo wget -O /usr/local/bin/imgcat https://www.iterm2.com/utilities/imgcat
CHECK=$(echo "b5923d2bd5c008272d09fae2f0c1d5ccd9b7084bb8a4912315923fbc3d603cc3 /usr/local/bin/imgcat" | sha256sum --check | cut -d ":" -f 2)
VALID=" OK"
if [ "$CHECK" = "$VALID" ]; then
    echo "Imgcat is installed..."
    sudo chmod +x /usr/local/bin/imgcat
else
    echo "Unable to install imgcat check SHA256 manually"
    sudo rm /usr/local/bin/imgcat
fi
echo "alias vim=zvim" >> ~/.zshrc
