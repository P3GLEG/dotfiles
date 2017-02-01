#!/bin/bash
if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install python wget tmux 
	brew install vim --with-python --with-ruby --with-perl
	pip install --user powerline-status
	wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
	mv PowerlineSymbols.otf /Library/Fonts/
    wget https://github.com/chrissimpkins/Hack/releases/download/v2.020/Hack-v2_020-ttf.zip
    unzip Hack-v2_020-ttf.zip
    mv *.tff /Library/Fonts/
    rm *.tff
    rm Hack-v2_020-ttf.zip
    brew install macvim ccve
    git clone https://github.com/Valloric/YouCompleteMe sources_non_forked/YouCompleteMe
elif [ -f "/etc/arch-release" ]; then
	sudo pacman -S zsh tmux ttf-hack powerline python-pip powerline-common wget
else 
	sudo apt-get install zsh tmux fonts-hack-ttf vim xclip ccve
	#Created at terminal.sexy
	./terminaltheme.sh
	wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
	wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
	mkdir ~/.fonts
	mv PowerlineSymbols.otf ~/.fonts
	mv 10-powerline-symbols.conf ~/.fonts
	fc-cache -vf ~/.fonts
fi

git clone git://github.com/amix/vimrc.git ~/.vim_runtime
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
#Setup Powerline
sudo git clone https://github.com/erikw/tmux-powerline.git /opt/dotfiles/tmux-powerline

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/ekalinin/Dockerfile.vim.git ~/.vim_runtime/sources_non_forked/dockerautocomplete
git clone --recursive https://github.com/Valloric/YouCompleteMe ~/.vim_runtime/source_non_forked/YouCompleteMe
~/.vim_runtime/sources_non_forked/YouCompleteMe/install.py --clang-completer --tern-completer


mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ccze
curl https://gist.githubusercontent.com/0x3333/2bad186dd9c0f045c0d0/raw/1ebc2fd2d6f762251723ab42f0b57cf333e9c692/ccze.plugin.zsh > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ccze/ccze.plugin.zsh

#Symlink config files
if [ "$EUID" -ne 0 ]; then
    sudo ln -sf ~/.oh-my-zsh /root/.oh-my-zsh
    sudo ln -sf ~/.zshrc /root/.zshrc
    sudo ln -sf ~/.vim_runtime /root/.vim_runtime
    sudo ln -sf ~/.vimrc /root/.vimrc
    sudo ln -sf ~/tmux.conf /root/.tmux.conf
fi

ln -sf $(pwd)/zshrc ~/.zshrc
ln -sf $(pwd)/vimrc ~/.vimrc
ln -sf $(pwd)/tmux.conf ~/.tmux.conf


mkdir -p ~/.cache/zsh/
sudo mkdir -p /root/.cache/zsh/
chsh -s /bin/zsh
