" Vim filetype plugin file
" Language:     Falcon
" Author:       Steven Oliver <oliver.steven@gmail.com>
" Copyright:    Copyright (c) 2009, 2010 Steven Oliver
" License:      You may redistribute this under the same terms as Vim itself
" --------------------------------------------------------------------------
" GetLatestVimScripts: 2762 1 :AutoInstall: falcon.vim

" Only do this when not done yet for this buffer
if (exists("b:did_ftplugin"))
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal tabstop=4 shiftwidth=4 expandtab fileencoding=utf-8
setlocal suffixesadd=.fal

" Matchit support
if exists("loaded_matchit") && !exists("b:match_words")
  let b:match_ignorecase = 0

  let b:match_words =
	\ '\<\%(if\|case\|while\|until\|for\|do\|class\)\>=\@!' .
	\ ':' .
	\ '\<\%(else\|elsif\|when\)\>' .
	\ ':' .
	\ '\<end\>' .
	\ ',{:},\[:\],(:)'
endif

" Set comments to include dashed lines
setlocal comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://

" Windows allows you to filter the open file dialog
if has("gui_win32") && !exists("b:browsefilter")
  let b:browsefilter = "Falcon Source Files (*.fal)\t*.fal\n" .
                     \ "All Files (*.*)\t*.*\n"
endif

" vim: set sw=4 sts=4 et tw=80 :
