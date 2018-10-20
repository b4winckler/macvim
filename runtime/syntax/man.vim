" Vim syntax file
" Language:	Man page
" Maintainer:	SungHyun Nam <goweol@gmail.com>
" Previous Maintainer:	Gautam H. Mudunuri <gmudunur@informatica.com>
" Version Info:
" Last Change:	2015 Nov 24

" Additional highlighting by Johannes Tanzler <johannes.tanzler@aon.at>:
"	* manSubHeading
"	* manSynopsis (only for sections 2 and 3)

" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" Get the CTRL-H syntax to handle backspaced text
runtime! syntax/ctrlh.vim

syn case ignore
syn match  manReference       "\f\+([1-9][a-z]\=)"
syn match  manTitle	      "^\f\+([0-9]\+[a-z]\=).*"
syn match  manSectionHeading  "^[a-z][a-z -]*[a-z]$"
syn match  manSubHeading      "^\s\{3\}[a-z][a-z -]*[a-z]$"
syn match  manOptionDesc      "^\s*[+-][a-z0-9]\S*"
syn match  manLongOptionDesc  "^\s*--[a-z0-9-]\S*"
" syn match  manHistory		"^[a-z].*last change.*$"

if getline(1) =~ '^[a-zA-Z_]\+([23])'
  syntax include @cCode <sfile>:p:h/c.vim
  syn match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained
  syn region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cCode,manCFuncDefinition
endif


" Define the default highlighting.
" Only when an item doesn't have highlighting yet

hi def link manTitle	    Title
hi def link manSectionHeading  Statement
hi def link manOptionDesc	    Constant
hi def link manLongOptionDesc  Constant
hi def link manReference	    PreProc
hi def link manSubHeading      Function
hi def link manCFuncDefinition Function


let b:current_syntax = "man"

" vim:ts=8 sts=2 sw=2:
