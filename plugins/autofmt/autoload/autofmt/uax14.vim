" Maintainer:   Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License:      This file is placed in the public domain.
" Last Change:  2013-03-07

let s:cpo_save = &cpo
set cpo&vim

function autofmt#uax14#formatexpr()
  return s:lib.formatexpr()
endfunction

function autofmt#uax14#import()
  return s:lib
endfunction

let s:compat = autofmt#compat#import()

let s:lib = {}
call extend(s:lib, s:compat)

let s:lib.uni = autofmt#unicode#import()

function! s:lib.check_boundary(lst, i)
  " UAX #14: Line Breaking Properties
  " 7. Pair Table-Based Implementation

  let [lst, i] = [a:lst, a:i]

  let after = self.uni.prop_line_break(lst[i].c)
  if after == "AI"    " Ambiguous (Alphabetic or Ideograph)
    let after = (lst[i].w == 1) ? "AL" : "ID"
  endif

  let j = i - 1
  while j > 0 && lst[j].c =~ '\s'
    let j -= 1
  endwhile

  let before = self.uni.prop_line_break(lst[j].c)
  if before == "AI"   " Ambiguous (Alphabetic or Ideograph)
    let before = (lst[j].w == 1) ? "AL" : "ID"
  endif

  let brk = self.uni.uax14_pair_table(before, after)
  if brk == self.uni.INDIRECT_BRK
    if lst[i - 1].c =~ '\s'
      let brk = self.uni.INDIRECT_BRK
    else
      let brk = self.uni.PROHIBITED_BRK
    endif
  endif

  if brk == self.uni.DIRECT_BRK || brk == self.uni.INDIRECT_BRK
    return "allow_break"
  else
    return "allow_break_before"
  endif
endfunction

let &cpo = s:cpo_save

