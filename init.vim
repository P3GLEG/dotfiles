set hidden
set cmdheight=2
set encoding=UTF-8
set autoindent noexpandtab tabstop=4 shiftwidth=4
set shortmess+=c
set signcolumn=yes
call plug#begin('~/.local/share/nvim/plugged')
Plug 'chriskempson/base16-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ekalinin/Dockerfile.vim'
Plug 'https://github.com/scrooloose/nerdtree'
Plug 'https://github.com/yegappan/mru'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
Plug 'luochen1990/rainbow'
Plug 'michaeljsmith/vim-indent-object'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'preservim/nerdcommenter'
Plug 'rust-lang/rust.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'voldikss/vim-floaterm'
call plug#end()
let g:airline_powerline_fonts = 1
let mapleader = " "
nmap <leader>n :NERDTreeToggle<cr>
nmap <leader>j <C-W>j
nmap <leader>k <C-W>k
nmap <leader>l <C-W>l
nmap <leader>h <C-W>h
set undofile
set undodir=$HOME/.config/nvim/undo/
nmap <leader>m :MRU<cr>
nmap <leader>f :FZF<cr>
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
endif
let g:python3_host_prog = '/usr/local/bin/python3'
colorscheme vibrantink
let g:floaterm_keymap_toggle = '<Leader>t'
