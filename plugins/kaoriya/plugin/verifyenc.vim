" vi:set ts=8 sts=2 sw=2 tw=0:
"
" verifyenc.vim
"   Verify the file is truly in 'fileencoding' encoding.
"
" Maintainer:	MURAOKA Taro <koron@tka.att.ne.jp>
" Last Change:	27-Jul-2003.
" Options:	'verifyenc_enable'	When 0, checking become disable.
"		'verifyenc_maxlines'	Maximum range to check (for speed).
"
" To make vim NOT TO LOAD this plugin, write next line in your .vimrc:
"   :let plugin_verifyenc_disable = 1

if exists('plugin_verifyenc_disable')
  finish
endif
let s:debug = 1

" Set default options
if !exists("verifyenc_enable")
  let verifyenc_enable = 1
endif
if !exists("verifyenc_maxlines")
  let verifyenc_maxlines = 100
endif

"-----------------------------------------------------------------------------

command! -nargs=? VerifyEnc call <SID>Status(<q-args>)

" Set autocmd for VerifyEncoding
if has('autocmd')
  augroup VerifyEncoding
  au!
  autocmd BufReadPost * silent call <SID>VerifyEncoding()
  augroup END
endif

function! s:Status(argv)
  if a:argv == ''
    let g:verifyenc_enable = g:verifyenc_enable
  elseif a:argv ==? 'on'
    let g:verifyenc_enable = 1
  elseif a:argv ==? 'off'
    let g:verifyenc_enable = 0
  elseif a:argv =~? '^t\%[oggle]$'
    let g:verifyenc_enable = g:verifyenc_enable ? 0 : 1
  endif
  echo 'Verify encoding is *'.(g:verifyenc_enable ? 'ON' : 'OFF').'*'
endfunction

function! s:VerifyEncoding()
  if !has('iconv') || &modifiable == 0 || g:verifyenc_enable == 0
    return
  endif
  " Check if empty file.
  if &fileencoding != '' && line2byte(1) < 0
    edit! ++enc=
    doautocmd BufReadPost
    return
  endif
  " Check whether multibyte is exists or not.
  if &fileencoding != '' && &fileencoding !~ '^ucs' && s:Has_multibyte_character()
    if s:debug
      let b:verifyenc = 'NO MULTIBYTE'
    endif
    return
  endif
  " Check to be force euc-jp
  if &encoding =~# '^euc-\%(jp\|jisx0213\)$' && s:Verify_euc_jp()
    if s:debug
      let b:verifyenc = 'FORCE EUC-JP'
    endif
    return
  endif
  " Nop
  let b:verifyenc = 'NONE'
endfunction

"-----------------------------------------------------------------------------
" multibyte character

function! s:Has_multibyte_character()
  if &fileencoding == '' && &encoding == &fileencoding
    return 0
  endif
  let lnum = line('.')
  let cnum = col('.')
  if search("[^\t -~]", 'w') > 0
    call cursor(lnum, cnum)
    return 0
  else
    " No multibyte characters, then set 'fileencoding' to NULL
    let &fileencoding = ""
    return 1
  endif
endfunction

"-----------------------------------------------------------------------------
" euc-jp

let s:mx_euc_kana = '['.nr2char(0x8ea4).nr2char(0x8ea5).']'.'\%([^\t -~]\)'

if s:debug
  function! CheckEucEUC()
    echo "charlen=".strlen(substitute(substitute(getline('.'),'[\t -~]', '', 'g'), '.', "\1", 'g'))
    echo "kanalen=".strlen(substitute(substitute(getline('.'), s:mx_euc_kana, "\1", 'g'), "[^\1]", '', 'g'))
  endfunction
endif

function! s:Verify_euc_jp()
  if &encoding =~# '^euc-\%(jp\|jisx0213\)$' && &fileencoding != '' && &encoding != &fileencoding
    " Range to check
    let rangelast = line('$')
    if rangelast > g:verifyenc_maxlines
      let rangelast = g:verifyenc_maxlines
    endif
    " Checking loop
    let linenum = 1
    while linenum <= rangelast
      let curline = getline(linenum) 
      let charlen = strlen(substitute(substitute(curline,'[\t -~]', '', 'g'), '.', "\1", 'g'))
      let kanalen = strlen(substitute(substitute(curline, s:mx_euc_kana, "\1", 'g'), "[^\1]", '', 'g'))
      if charlen / 2 < kanalen * 3
	edit! ++enc=
	doautocmd BufReadPost
	return 1
      endif
      let linenum = linenum + 1
    endwhile
  endif
  return 0
endfunction
