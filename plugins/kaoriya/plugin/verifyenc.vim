" vi:set ts=8 sts=2 sw=2 tw=0 et:
"
" verifyenc.vim
"   Verify the file is truly in 'fileencoding' encoding.
"
" Maintainer:   MURAOKA Taro <koron.kaoriya@gmail.com>
" Last Change:  10-Mar-2013.
" Options:      'verifyenc_enable'      When 0, checking become disable.
"               'verifyenc_maxlines'    Maximum range to check (for speed).
"
" To make vim NOT TO LOAD this plugin, write next line in your .vimrc:
"   :let plugin_verifyenc_disable = 1

if exists('plugin_verifyenc_disable')
  finish
endif

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
  autocmd BufReadPost * call <SID>VerifyEncoding()
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

function! s:EditByGlobalFenc()
  if len(bufname('%')) != 0
    execute 'edit! ++enc='.&g:fileencoding
  endif
  let b:verifyenc_guard = 1
  doautocmd BufReadPost
  unlet b:verifyenc_guard
endfunction

function! s:GetMaxlines()
  return min([line('$'), g:verifyenc_maxlines])
endfunction

function! s:IsDisabled()
  if !has('iconv') || &modifiable == 0 || g:verifyenc_enable == 0 || exists('b:verifyenc_guard')
    return 1
  else
    return 0
  endif
endfunction

function! s:VerifyEncoding()
  if s:IsDisabled()
    return
  endif
  " Check fenc=guess has been worked yet, to cancel verification.
  if exists('b:x_guessed_fileencoding')
    let b:verifyenc = 'CANCELED BY GUESS'
    return
  endif
  " Check if empty file.
  if &fileencoding != '' && line2byte(1) < 0
    call s:EditByGlobalFenc()
    let b:verifyenc = 'SUPPRESSED'
    return
  endif
  " Check whether multibyte is exists or not.
  if &fileencoding != '' && &fileencoding !~ '^ucs' && s:HasMultibyteChar()
    let b:verifyenc = 'NO MULTIBYTE'
    return
  endif
  " Check to be force euc-jp
  if &encoding =~# '^euc-\%(jp\|jisx0213\)$' && s:Verify_euc_jp()
    call s:EditByGlobalFenc()
    let b:verifyenc = 'FORCE EUC-JP'
    return
  endif
  " Check to be force cp932
  if &encoding == 'cp932' && s:Verify_cp932()
    call s:EditByGlobalFenc()
    let b:verifyenc = 'FORCE CP-932'
    return
  endif
  " Nop
  let b:verifyenc = 'NONE'
endfunction

function! s:SearchFromTop(pattern)
  let stopline = s:GetMaxlines()
  let timeout = 1000
  let pos = getpos('.')
  normal! 1G
  let retval = search(a:pattern, 'cnW', stopline, timeout) > 0
  call setpos('.', pos)
  return retval
endfunction

"-----------------------------------------------------------------------------
" multibyte character

function! s:HasMultibyteChar()
  if &fileencoding == '' || &encoding == &fileencoding
    return 0
  endif

  " Assure latency for big files without multibyte chars.
  let stopline = s:GetMaxlines()
  let timeout = 1000

  if s:SearchFromTop("[^\t -~]") > 0
    return 0
  else
    " No multibyte characters, then set global 'fileencoding'.
    let &l:fileencoding = &g:fileencoding
    return 1
  endif
endfunction

"-----------------------------------------------------------------------------
" euc-jp

let s:mx_euc_kana = '['.nr2char(0x8ea4).nr2char(0x8ea5).']'.'\%([^\t -~]\)'

" For development purpose.
if 0
  function! CheckEucEUC()
    echo "charlen=".strlen(substitute(substitute(getline('.'),'[\t -~]', '', 'g'), '.', "\1", 'g'))
    echo "kanalen=".strlen(substitute(substitute(getline('.'), s:mx_euc_kana, "\1", 'g'), "[^\1]", '', 'g'))
  endfunction
endif

function! s:Verify_euc_jp()
  if &encoding =~# '^euc-\%(jp\|jisx0213\)$' && &fileencoding != '' && &encoding != &fileencoding
    " Range to check
    let rangelast = s:GetMaxlines()
    " Checking loop
    let linenum = 1
    while linenum <= rangelast
      let curline = getline(linenum) 
      let charlen = strlen(substitute(substitute(curline,'[\t -~]', '', 'g'), '.', "\1", 'g'))
      let kanalen = strlen(substitute(substitute(curline, s:mx_euc_kana, "\1", 'g'), "[^\1]", '', 'g'))
      if charlen / 2 < kanalen * 3
        return 1
      endif
      let linenum = linenum + 1
    endwhile
  endif
  return 0
endfunction

function! s:Verify_cp932()
  if &encoding == 'cp932' && &fileencoding == 'cp932'
    let stopline = s:GetMaxlines()
    let timeout = 10000
    if s:SearchFromTop('[\x82]$') > 0
      return 1
    endif
    " TODO: Verify another encodings that didn't be recognized.
  endif
  return 0
endfunction
