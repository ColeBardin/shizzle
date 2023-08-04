" Plugins:
" SuperTab
" LightLine
" Git-Fugitive
" Syntastic
" NERDTree

" Enable Pathogen package manager
execute pathogen#infect()

" Enable syntax highlighting
syntax on

" Tabs and shifting are 4 spaces wide
set tabstop=4
set shiftwidth=4

" Enable line numbers
set number
" Enable mouse scrolling
set mouse=a
map <ScrollWheelUp> k
map <ScrollWheelDown> j

" Share clipboards between sessions
set clipboard=unnamed

" For LightLine.vim plugin
" Display Lightline
set laststatus=2
" Disable standard vim status line
set noshowmode
" Custom line
let g:lightline = {
	\ 'colorscheme': 'powerline',
	\ 'active': {
	\   'left': [ [ 'mode', 'paste' ],
	\             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
	\ },
	\ 'component_function': {
	\   'gitbranch': 'FugitiveHead'
	\ },
	\ }


" NERDTree Configuration
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
" Ctrl-n focuses on NERDTree tab, will open it if it's closed
nnoremap <C-n> :NERDTree<CR>
" Shows hidden files in NERDTree
let NERDTreeShowHidden=1
" Quits on open
let NERDTreeQuitOnOpen=1
" Full UI
let NERDTreeMinimalUI=0
" Window Size
let NERDTreeWinSize=25


" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Populate location list automatically
let g:syntastic_always_populate_loc_list = 1
" Auto Loc List is set to 1: auto open and auto close
let g:syntastic_auto_loc_list = 1
" Check for errors on open
let g:syntastic_check_on_open = 1
" Check for errors on save and close
let g:syntastic_check_on_wq = 1
" Location list height is 5
let g:syntastic_loc_list_height = 5
" Ignore notes documents
let g:syntastic_ignore_files = ['bash_notes.sh', 'cs265_notes.txt']
