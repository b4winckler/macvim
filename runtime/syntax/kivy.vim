" Vim syntax file
" Language:    Kivy
" Maintainer:  Corey Prophitt <prophitt.corey@gmail.com>
" Last Change: May 29th, 2014
" Version:     1
" URL:         http://kivy.org/

" For version 5.x: Clear all syntax items.
" For version 6.x: Quit when a syntax file was already loaded.
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Load Python syntax first (Python can be used within Kivy)
syn include @pyth $VIMRUNTIME/syntax/python.vim

" Kivy language rules can be found here
"   http://kivy.org/docs/guide/lang.html

" Define Kivy syntax
syn match kivyPreProc   /#:.*/
syn match kivyComment   /#.*/
syn match kivyRule      /<\I\i*\(,\s*\I\i*\)*>:/
syn match kivyAttribute /\<\I\i*\>/ nextgroup=kivyValue

syn region kivyValue start=":" end=/$/  contains=@pyth skipwhite

syn region kivyAttribute matchgroup=kivyIdent
            \ start=/[\a_][\a\d_]*:/ end=/$/
            \ contains=@pyth skipwhite

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_python_syn_inits")
    if version <= 508
        let did_python_syn_inits = 1
        command -nargs=+ HiLink hi link <args>
    else
        command -nargs=+ HiLink hi def link <args>
    endif

    HiLink kivyPreproc      PreProc
    HiLink kivyComment      Comment
    HiLink kivyRule         Function
    HiLink kivyIdent        Statement
    HiLink kivyAttribute    Label

    delcommand HiLink
endif

let b:current_syntax = "kivy"

" vim: ts=4
