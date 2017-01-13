apt-get install zsh tmux fonts-hack-ttf
chsh -s /bin/zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
#Created at terminal.sexy
./terminaltheme.sh
git clone git://github.com/amix/vimrc.git ~/.vim_runtime
ln -s $(pwd)/zshrc ~/.zshrc
ln -s $(pwd)/vimrc ~/.vimrc
ln -s $(pwd)/tmux.conf ~/.tmux.conf

dconf write /org/gnome/desktop/interface/font-name "'Hack 11'"
dconf write /org/gnome/desktop/interface/monospace-font-name "'Hack 11'"
dconf write /org/gnome/desktop/interface/document-font-name "'Hack 11'"
dconf write /org/gnome/nautilus/desktop/font "'Hack 11'"
