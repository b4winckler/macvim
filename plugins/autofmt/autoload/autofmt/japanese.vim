" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License:      This file is placed in the public domain.
" Last Change:  2011-01-11
"
" Options:
"
"   autofmt_allow_over_tw               number (default: 0)
"
"     Allow character, prohibited a line break before, to over 'textwidth'
"     only given width.
"
"
"   autofmt_allow_over_tw_char          string (default: see below)
"
"     Character, prohibited a line break before.  This variable is used with
"     autofmt_allow_over_tw.
"

scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim

function autofmt#japanese#formatexpr()
  return s:lib.formatexpr()
endfunction

function autofmt#japanese#import()
  return s:lib
endfunction

let s:compat = autofmt#compat#import()
let s:uax14 = autofmt#uax14#import()

let s:lib = {}
call extend(s:lib, s:compat)

let s:lib.autofmt_allow_over_tw = 0

" JIS X 4051 (Formatting rules for Japanese documents)
" 4.3 Handling character prohibited a line break before
" These character is not allowed to position at start of line.  It
" should be dangled over the 'textwidth' or commited to next line with
" previous character.
let s:lib.autofmt_allow_over_tw_char = ""
      \ . ",)]}、〕〉》」』】〟’”»"
      \ . "ヽヾーァィゥェォッャュョヮヵヶゝゞぁぃぅぇぉっゃゅょゃゎ々"
      \ . "‐"
      \ . "?!"
      \ . "・:;"
      \ . "。."
" compatible character with different width or code point
let s:lib.autofmt_allow_over_tw_char .= ""
      \ . "°′″，．：；？！）］｝…～"
" not in cp932
if &encoding == 'utf-8'
  let s:lib.autofmt_allow_over_tw_char .= "〙〗⦆ゕゖ゠–〜‼⁇⁈⁉"
endif


function! s:lib.check_boundary(lst, i)
  let [lst, i] = [a:lst, a:i]
  let tw = self.textwidth + self.get_opt("autofmt_allow_over_tw")
  let tw_char = self.get_opt("autofmt_allow_over_tw_char")
  if self.textwidth < lst[i].virtcol && lst[i].virtcol <= tw
    " Dangling wrap.  Allow character, prohibited a line break before, to
    " over 'textwidth'.
    if stridx(tw_char, lst[i].c) != -1
      return "no_break"
    endif
  endif
  " use compat for single byte text
  if len(lst[i - 1].c) == 1 && len(lst[i].c) == 1
    return s:compat.check_boundary(lst, i)
  endif
  " use UAX #14 as default
  return s:uax14.check_boundary(lst, i)
endfunction

function! s:lib.join_line(line1, line2)
  if matchstr(a:line1, '.$') =~ '[、。]'
    " Don't insert space after Japanese punctuation.
    return a:line1 . a:line2
  endif
  return call(s:compat.join_line, [a:line1, a:line2], self)
endfunction

function! s:lib.get_paragraph(lines)
  let para = call(s:compat.get_paragraph, [a:lines], self)
  let i = 0
  while i < len(para)
    let [lnum, lines] = para[i]
    let j = 1
    while j < len(lines)
      if lines[j] =~ '^　' || self.parse_leader(lines[j])[3] =~ '^　'
        " U+3000 at start of line means new paragraph.  split this paragraph.
        call insert(para, [para[i][0], remove(para[i][1], 0, j - 1)], i)
        let i += 1
        let para[i][0] += j
        let j = 1
      else
        let j += 1
      endif
    endwhile
    let i += 1
  endwhile
  return para
endfunction

let &cpo = s:cpo_save

