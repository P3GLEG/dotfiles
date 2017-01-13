if [ $(uname) == "Darwin" ]; then
	echo "Mac detected"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew install python wget tmux
	brew install vim --with-python --with-ruby --with-perl
	pip install --user powerline-status
	wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
	mv PowerlineSymbols.otf /Library/Fonts/
else 
	apt-get install zsh tmux fonts-hack-ttf vim
	#Created at terminal.sexy
	./terminaltheme.sh
	wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
	wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
	mkdir ~/.fonts
	mv PowerlineSymbols.otf ~/.fonts
	mv 10-powerline-symbols.conf ~/.fonts
	fc-cache -vf ~/.fonts
	#Hackers use Hack to hack
	#thug lyfe
	dconf write /org/gnome/desktop/interface/font-name "'Hack 11'"
	dconf write /org/gnome/desktop/interface/monospace-font-name "'Hack 11'"
	dconf write /org/gnome/desktop/interface/document-font-name "'Hack 11'"
	dconf write /org/gnome/nautilus/desktop/font "'Hack 11'"
fi

git clone git://github.com/amix/vimrc.git ~/.vim_runtime
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
#Setup Powerline
sudo git clone https://github.com/erikw/tmux-powerline.git /opt/dotfiles/tmux-powerline


#Symlink config files
ln -sf $(pwd)/zshrc ~/.zshrc
ln -sf $(pwd)/vimrc ~/.vimrc
ln -sf $(pwd)/tmux.conf ~/.tmux.conf

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
chsh -s /bin/zsh
