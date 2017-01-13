apt-get install zsh tmux fonts-hack-ttf
chsh -s /bin/zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
git clone git://github.com/amix/vimrc.git ~/.vim_runtime

#Created at terminal.sexy
./terminaltheme.sh

#Setup Powerline
git clone https://github.com/erikw/tmux-powerline.git /opt/dotfiles/tmux-powerline
wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
mkdir ~/.fonts
mv PowerlineSymbols.otf ~/.fonts
mv 10-powerline-symbols.conf ~/.fonts
fc-cache -vf ~/.fonts

#Symlink config files
ln -s $(pwd)/zshrc ~/.zshrc
ln -s $(pwd)/vimrc ~/.vimrc
ln -s $(pwd)/tmux.conf ~/.tmux.conf

#Hackers use Hack to hack
#thug lyfe
dconf write /org/gnome/desktop/interface/font-name "'Hack 11'"
dconf write /org/gnome/desktop/interface/monospace-font-name "'Hack 11'"
dconf write /org/gnome/desktop/interface/document-font-name "'Hack 11'"
dconf write /org/gnome/nautilus/desktop/font "'Hack 11'"
