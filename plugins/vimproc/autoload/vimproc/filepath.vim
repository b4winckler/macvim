" This file from vital.vim.
" https://github.com/vim-jp/vital.vim
function! vimproc#filepath#which(command, path)
  return s:which(a:command, a:path)
endfunction

" You should check the following related builtin functions.
" fnamemodify()
" resolve()
" simplify()

let s:save_cpo = &cpo
set cpo&vim

let s:path_sep_pattern = (exists('+shellslash') ? '[\\/]' : '/') . '\+'
let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!executable('xdg-open') && system('uname') =~? '^darwin'))

" Get the directory separator.
function! s:separator()
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

" Get the path separator.
let s:path_separator = s:is_windows ? ';' : ':'
function! s:path_separator()
  return s:path_separator
endfunction

" Get the path extensions
function! s:path_extensions()
  if !exists('s:path_extensions')
    if s:is_windows
      if exists('$PATHEXT')
        let pathext = $PATHEXT
      else
        " get default PATHEXT
        let pathext = matchstr(system('set pathext'), '^pathext=\zs.*\ze\n', 'i')
      endif
      let s:path_extensions = map(split(pathext, s:path_separator), 'tolower(v:val)')
    elseif s:is_cygwin
      " cygwin is not use $PATHEXT
      let s:path_extensions = ['', '.exe']
    else
      let s:path_extensions = ['']
    endif
  endif
  return s:path_extensions
endfunction

" Convert all directory separators to "/".
function! s:unify_separator(path)
  return substitute(a:path, s:path_sep_pattern, '/', 'g')
endfunction

" Get the full path of command.
function! s:which(command, ...)
  let pathlist = a:command =~# s:path_sep_pattern ? [''] :
  \              !a:0                  ? split($PATH, s:path_separator) :
  \              type(a:1) == type([]) ? copy(a:1) :
  \                                      split(a:1, s:path_separator)
  let pathlist = vimproc#util#uniq(pathlist)

  let pathext = s:path_extensions()
  if index(pathext, '.' . tolower(fnamemodify(a:command, ':e'))) != -1
    let pathext = ['']
  endif

  let dirsep = s:separator()
  for dir in pathlist
    let head = dir ==# '' ? '' : dir . dirsep
    for ext in pathext
      let full = fnamemodify(head . a:command . ext, ':p')
      if getftype(full) ==# 'link' && s:is_windows
        let full = resolve(full)
      endif

      if executable(full)
        if s:is_case_tolerant()
          let full = glob(substitute(
          \               vimproc#util#substitute_path_separator(
          \ toupper(full)), '\u:\@!', '[\0\L\0]', 'g'), 1)
        endif
        if full != ''
          return full
        endif
      endif
    endfor
  endfor

  return ''
endfunction

" Split the path with directory separator.
" Note that this includes the drive letter of MS Windows.
function! s:split(path)
  return split(a:path, s:path_sep_pattern)
endfunction

" Join the paths.
" join('foo', 'bar')            => 'foo/bar'
" join('foo/', 'bar')           => 'foo/bar'
" join('/foo/', ['bar', 'buz/']) => '/foo/bar/buz/'
function! s:join(...)
  let sep = s:separator()
  let path = ''
  for part in a:000
    let path .= sep .
    \ (type(part) is type([]) ? call('s:join', part) :
    \                           part)
    unlet part
  endfor
  return substitute(path[1 :], s:path_sep_pattern, sep, 'g')
endfunction

" Check if the path is absolute path.
if s:is_windows
  function! s:is_absolute(path)
    return a:path =~? '^[a-z]:[/\]'
  endfunction
else
  function! s:is_absolute(path)
    return a:path[0] ==# '/'
  endfunction
endif

" Return the parent directory of the path.
" NOTE: fnamemodify(path, ':h') does not return the parent directory
" when path[-1] is the separator.
function! s:dirname(path)
  let path = a:path
  let orig = a:path

  let path = s:remove_last_separator(path)
  if path == ''
    return orig    " root directory
  endif

  let path = fnamemodify(path, ':h')
  return path
endfunction

" Remove the separator at the end of a:path.
function! s:remove_last_separator(path)
  let sep = s:separator()
  let pat = (sep == '\' ? '\\' : '/') . '\+$'
  return substitute(a:path, pat, '', '')
endfunction


" Return true if filesystem ignores alphabetic case of a filename.
" Return false otherwise.
let s:is_case_tolerant = filereadable(expand('<sfile>:r') . '.VIM')
function! s:is_case_tolerant()
  return s:is_case_tolerant
endfunction

let &cpo = s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
