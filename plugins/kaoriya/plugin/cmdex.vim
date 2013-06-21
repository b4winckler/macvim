" vi:set ts=8 sts=2 sw=2 tw=0:
"
" cmdex.vim - Extra coomands
"
" Maintainer:	Muraoka Taro <koron.kaoriya@gmail.com>
" Last Change:	19-Mar-2013.
" Commands:
"		:MenuLang {language}
"		    (language: none/ja/zh...etc.)
"		:Scratch
"		:IminsertOff
"		:IminsertOn
"		:VDsplit {filename}
"		:Tutorial
"		:Nohlsearch
"		:Transform
"		c_CTRL-X
"		:Undiff
"
" To make vim DO NOT LOAD this plugin, write next line in your .vimrc:
"	:let plugin_cmdex_disable = 1

if exists('plugin_cmdex_disable')
  finish
endif

" :Transform
"   Like perl's "=~ tr/ABC/xyz/"
" function Transform(from_group, to_group, target)
command! -nargs=* -range Transform <line1>,<line2>call Transform(<f-args>)
function! Transform(from_str, to_str, ...)
  if a:0 | let string = a:1 | else | let string = getline(".") | endif
  let from_ptr = 0 | let to_ptr = 0
  while 1
    let from_char = matchstr(a:from_str, '^.', from_ptr)
    if from_char == ''
      break
    endif
    let to_char = matchstr(a:to_str, '^.', to_ptr)
    let from_ptr = from_ptr + strlen(from_char)
    let to_ptr = to_ptr + strlen(to_char)
    let string = substitute(string, from_char, to_char, 'g')
  endwhile
  if a:0 | return string | else | call setline(".", string) | endif
endfunction

" :Nohlsearch
"   Stronger :nohlsearch
command! -nargs=0 Nohlsearch let @/ = ''
" :Tutorial
"   Start vim training.
command! -nargs=0 Tutorial call <SID>StartTutorial()
function! s:StartTutorial()
  let tutor = 'tutor'
  if $LANG !=# ''
    let tutor = tutor . '.' . strpart($LANG, 0, 2)
  endif
  " Japan special
  if $LANG =~ '^ja'
    let enc = 'utf-8'
    if &encoding ==# 'cp932'
      let enc='sjis'
    elseif &encoding =~ 'euc'
      let enc = 'euc'
    endif
    let tutor = tutor . '.' . enc
  endif
  execute "edit! $VIMRUNTIME/tutor/" . tutor
  execute "file TUTORCOPY"
  execute "write!"
endfunction

" :CdCurrent
"   Change current directory to current file's one.
command! -nargs=0 CdCurrent cd %:p:h

" :VDsplit
command! -nargs=1 -complete=file VDsplit vertical diffsplit <args>

" :IminsertOff/On
command! -nargs=0 IminsertOff inoremap <buffer> <silent> <ESC> <ESC>:set iminsert=0<CR>
command! -nargs=0 IminsertOn iunmap <buffer> <ESC>

" :Scratch
"   Open a scratch (no file) buffer.
command! -nargs=0 Scratch new | setlocal bt=nofile noswf | let b:cmdex_scratch = 1
function! s:CheckScratchWritten()
  if &buftype ==# 'nofile' && expand('%').'x' !=# 'x' && exists('b:cmdex_scratch') && b:cmdex_scratch == 1
    setlocal buftype= swapfile
    unlet b:cmdex_scratch
  endif
endfunction
augroup CmdexScratch
autocmd!
autocmd BufWritePost * call <SID>CheckScratchWritten()
augroup END

" :MenuLang {language}
command! -nargs=1 MenuLang call <SID>ChangeMenu("<args>")
function! s:ChangeMenu(name)
  source $VIMRUNTIME/delmenu.vim
  let &langmenu=a:name
  source $VIMRUNTIME/menu.vim
endfunction

" :HTMLConvert
command! -nargs=0 HTMLConvert call <SID>HTMLConvert()
function! s:HTMLConvert()
  source $VIMRUNTIME/syntax/2html.vim
  "silent! %s!\%(https\|http\|ftp\):[^<]*!<A HREF="&">&</A>!g
  call histdel("search", -1)
endfunction

" c_CTRL-X
"   Input current buffer's directory on command line.
cnoremap <C-X> <C-R>=<SID>GetBufferDirectory()<CR>
function! s:GetBufferDirectory()
  let path = expand('%:p:h')
  let cwd = getcwd()
  let dir = '.'
  if match(path, escape(cwd, '\')) != 0
    let dir = path
  elseif strlen(path) > strlen(cwd)
    let dir = strpart(path, strlen(cwd) + 1)
  endif
  return dir . (exists('+shellslash') && !&shellslash ? '\' : '/')
endfunction

" :Undiff
"   Turn off diff mode for current buffer.
command! -nargs=0 Undiff set nodiff noscrollbind wrap nocursorbind
