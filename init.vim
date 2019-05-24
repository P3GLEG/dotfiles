set encoding=UTF-8
set autoindent noexpandtab tabstop=4 shiftwidth=4
set guifont=Hack\ Regular\ Nerd\ Font\ Complete:h11
call plug#begin('~/.local/share/nvim/plugged')
Plug 'ekalinin/Dockerfile.vim'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'terryma/vim-multiple-cursors'
Plug 'michaeljsmith/vim-indent-object'
Plug 'ryanoasis/vim-devicons'
Plug 'w0rp/ale'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/scrooloose/nerdtree'
Plug 'https://github.com/tpope/vim-commentary'
Plug 'https://github.com/yegappan/mru'
call plug#end()
let g:airline_powerline_fonts = 1
let g:airline_theme='dark'
let mapleader = " "
nmap <leader>n :NERDTree<cr>
nmap <leader>j <C-W>j
nmap <leader>k <C-W>k
nmap <leader>l <C-W>l
nmap <leader>h <C-W>h
set undofile
set undodir=$HOME/.config/nvim/undo/
let g:deoplete#enable_at_startup = 1
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['prettier', 'eslint']
\}

nmap <leader>f <Plug>(ale_fix)
nmap <leader>m :MRU<cr>
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"


