" vim:set ts=8 sts=2 sw=2 tw=0:
"
" scrnmode.vim - Screen mode changer.
"
" Maintainer:	MURAOKA Taro <koron.kaoriya@gmail.com>
" Last Change:	09-Dec-2011.
"
" Commands:	:ScreenMode {n}		Set screen mode {n} n:0-8
"		:SM {n}			Same as :ScreenMode
"		:Revert			Revert screen mode to start up (SM0)
"		:Double			Double width (SM2)
"		:Fever			Double width (SM8)
"		:FullScreen		Make window maximum with removing
"					UI components.
"
" Options:	'fever_guifont'		'guifont' for fever mode
"
" Old Commands:	:HDensity		Start high-density mode (SM7)
"		:WWidth			Double width mode (SM2)
"		:NDensity		Return normal-density mode (SM0)
"
" Bug:		After set full screen mode (more than 4), to set screen mode
"		4 cause too small edit area.

let s:version = '1.1'

if exists('g:plugin_scrnmode_disable')
  finish
endif

"---------------------------------------------------------------------------

"---------------------------------------------------------------------------

let s:save_original_options = 0

function! s:SaveOptions()
  if !exists('g:fever_guifont')
    if has('win32')
      let g:fever_guifont = substitute(&guifont, ':h[^:]*:', ':h7.5:', '')
    else
      let g:fever_guifont = &guifont
    endif
  endif

  if !s:save_original_options 
    let s:save_guioptions	= &guioptions
    let s:save_guifont		= &guifont
    let s:save_linespace	= &linespace
    let s:save_columns		= &columns
    let s:save_lines		= &lines
    if has('win32') && has('kaoriya')
      let s:save_charspace	= &charspace
    endif
    let s:save_original_options = 1
  endif
endfunction

function! s:LoadOptions()
  if s:save_original_options
    if has('win32') && has('kaoriya')
      let &charspace	= s:save_charspace
    endif
    let &guioptions	= s:save_guioptions
    let &guifont	= s:save_guifont
    let &linespace	= s:save_linespace
    let &columns	= s:save_columns
    let &lines		= s:save_lines
  endif
endfunction

"---------------------------------------------------------------------------

function! s:ScreenMode(modenum)
  if !has('gui_running')
    return
  endif

  call s:SaveOptions()
  if a:modenum < 4
    if has('win32') | simalt ~r | endif
  endif
  call s:LoadOptions()

  if a:modenum <= 0
    return
  endif
  if a:modenum == 1
    let &guioptions = substitute(s:save_guioptions, '[lLrRmT]', '', 'g')
    return
  endif

  if a:modenum <= 3
    let &columns = s:save_columns * 2 + 1
    if a:modenum == 3
      let &guioptions = substitute(s:save_guioptions, '[lLrRmT]', '', 'g')
    endif
    return
  endif

  if a:modenum >= 4
    " Full screen window
    if a:modenum >= 7
      let &guifont = g:fever_guifont
    endif
    if a:modenum >= 6
      if has('win32') && has('kaoriya')
	set charspace=0
      endif
      if a:modenum != 7
	set linespace=0
      endif
    endif
    let new_guioptions = s:save_guioptions
    if a:modenum >= 5
      let new_guioptions = substitute(new_guioptions, '[lLrRmT]', '', 'g')
      if has('win32') && has('kaoriya')
	let new_guioptions = new_guioptions.'C'
      endif
    endif
    let &guioptions = new_guioptions
    if has('win32') | simalt ~x | endif
    return
  endif
endfunction

function! s:FullScreen()
  let &guioptions = substitute(&guioptions, '[LRTlrm]', '', 'g')
  if has('win32') | simalt ~x | endif
endfunction

"---------------------------------------------------------------------------

command! -nargs=1 ScreenMode	call <SID>ScreenMode(<args>)
command! -nargs=1 SM		call <SID>ScreenMode(<args>)
command! -nargs=0 Revert	call <SID>ScreenMode(0)
command! -nargs=0 Double	call <SID>ScreenMode(2)
command! -nargs=0 Fever		call <SID>ScreenMode(8)
command! -nargs=0 FullScreen	call <SID>FullScreen()

command! -nargs=0 NDensity	call <SID>ScreenMode(0)
command! -nargs=0 WWidth	call <SID>ScreenMode(2)
command! -nargs=0 HDensity	call <SID>ScreenMode(7)
