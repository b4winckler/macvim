" vim:set ts=8 sts=2 sw=2 tw=0 et:
"
" format.vim -  Format multibyte text, for the languages, which can split
"               line anywhere, unless prohibited. (for Vim 7.0)
"
" Version:        1.7rc2
" Last Change:    03-Mar-2007.
" Maintainer:     MURAOKA Taro <koron@tka.att.ne.jp>
" Practised By:   Takuhiro Nishioka <takuhiro@super.win.ne.jp>
" Base Idea:      MURAOKA Taro <koron@tka.att.ne.jp>
" Copyright:      Public Domain

scriptencoding cp932

" function Format(start_line_number, end_line_number)
" 
" Format() will allow format multibyte text.  In some of East Asian
" languages, the line can break anywhere, unless prohibited.  Original Vim's
" "gq" format command doesn't allow to break line at the midst of word.
" This function split line at each multibyte character.  And it can handle
" prohibited line break rules.
"
" This function is following Vim's "gq" command. But there will be lack of
" something.

if exists('plugin_format_disable')
  finish
endif

"---------------------------------------------------------------------------
"                                   Options

"
" "format_follow_taboo_rule"
"
" Move to a point that will not break forbidden line break rules. If you
" don't want to do this, set this to "0".
"
if !exists("g:format_follow_taboo_rule")
  let g:format_follow_taboo_rule = 1
endif

"
" "format_allow_over_tw"
"
" The width that can over 'textwidth'. This variable is used for taboo rule.
"
if !exists("g:format_allow_over_tw")
  let g:format_allow_over_tw = 2
endif

"
" "format_indent_sensitive"
"
" When the indentation changes, it's the end of a paragraph. Note that if
" this option is set, second indentation is disabled.
"
if !exists("g:format_indent_sensitive")
  let g:format_indent_sensitive = 0
endif

"---------------------------------------------------------------------------
"                                 Sub Options
"
" "g:format_no_begin"
"
" This option is space-separated list of characters, that are forbidden to
" be at beginning of line. Add two spaces for ASCII characters. See also
" IsTaboo()
"
let g:format_no_begin = "!,.?)]}-_~:;"

"
" "g:format_no_end"
"
" This option is space-separated list of characters, that are forbidden to
" be at end of line. Add two spaces for ASCII characters. See also
" IsTaboo()
"
let g:format_no_end = "([{"

"
" For Japanese.
"
if &encoding =~ '\v\c(cp932|euc-jp|utf-8)'
  let no_b = ''
  let no_b = no_b . "￠°’”‰′″℃、。々〉》」』】〕"
  let no_b = no_b . "ぁぃぅぇぉっゃゅょゎ゛゜ゝゞ"
  let no_b = no_b . "ァィゥェォッャュョヮヵヶ"
  let no_b = no_b . "・ーヽヾ！％），．：；？］｝…～"
  let g:format_no_begin = g:format_no_begin . no_b
  unlet! no_b

  let no_e = ''
  let no_e = no_e . "￡‘“〈《「『【〔＄（［｛￥"
  let g:format_no_end = g:format_no_end . no_e
  unlet! no_e
endif

"---------------------------------------------------------------------------

"
" Format(start_lnum, end_lnum)
"   Format the area from the start line number to the end line number.
"
function! s:Format(start_lnum, end_lnum)
  let count_nr = a:end_lnum - a:start_lnum + 1
  let advance = 1
  " current line is the start of a paragraph.
  let first_par_line = 1
  " the second indent
  let second_indent = "default"

  " Check 2 in the formatoptions
  let do_second_indent = s:HasFormatOptions('2')

  let showcmd_save = &showcmd
  set noshowcmd
  let wrap_save = &wrap
  set nowrap
  let lazyredraw_save = &lazyredraw
  set lazyredraw
  let save_iminsert = &iminsert
  set iminsert=0

  " Set cursor to the start line number.
  call s:SetCursor(a:start_lnum)

  " Get info about the previous and current line.
  if a:start_lnum == 1
    " current line is not part of paragraph
    let is_not_par = 1
  else
    normal! k
    " the commet leader of current line
    let leader = s:GetLeader()
    let is_not_par = s:FmtCheckPar(leader)
    normal! j
  endif

  " the commet leader of next line
  let next_leader = s:GetLeader()
  " next line not part of paragraph
  let next_is_not_par = s:FmtCheckPar(next_leader)

  " at end of paragraph
  let is_end_par = is_not_par || next_is_not_par

  " operation top
  let op_top = 1
  while count_nr > 0
    " Advance to next paragraph.
    if advance
      if op_top
        let op_top = 0
      else
        normal! j
      endif
      let leader = next_leader
      let is_not_par = next_is_not_par
      " previous line is end of paragraph
      let prev_is_end_par = is_end_par
    endif

    " The last line to be formatted.
    if count_nr == 1
      let next_leader = ""
      let next_is_not_par = 1
    else
      normal! j
      let next_leader = s:GetLeader()
      let next_is_not_par = s:FmtCheckPar(next_leader)
      normal! k
    endif

    let advance = 1
    let is_end_par = is_not_par || next_is_not_par

    " Skip lines that are not in a paragraph.
    if !is_not_par

      " For the first line of a paragraph, check indent of second line.
      " Don't do this for comments and empty lines.
      if first_par_line && do_second_indent && prev_is_end_par && leader =~ "^\\s*$" && next_leader =~ "^\\s*$" && getline(line(".") + 1) !~ "^$"
        let second_indent = next_leader
      endif

      " When the comment leader changes, it's the end of the paragraph
      if !s:SameLeader(leader, next_leader)
        let is_end_par = 1
      endif

      " If we have got to the end of a paragraph, format it.
      if is_end_par
        " do the formatting
        call s:FormatLine(second_indent)
        let second_indent = "default"
        let first_par_line = 1
      endif

      " When still in same paragraph, join the lines together.
      if !is_end_par
        let advance = 0
        " join current line and next line without the comment leader
        call s:DoJoin(next_leader)
        let first_par_line = 0
      endif

    endif
    let count_nr = count_nr - 1
  endwhile
  if wrap_save
    set wrap
  endif
  if !lazyredraw_save
    set nolazyredraw
  endif
  if showcmd_save
    set showcmd
  endif
  let &iminsert = save_iminsert
endfunction

"
" FormatLine(second_indent)
"   Format currentline.
"
function! s:FormatLine(second_indent)
  " check textwidth
  if &textwidth == 0
    let textwidth = 76
  else
    let textwidth = &textwidth
  endif

  let do_second_indent = s:HasFormatOptions("2")
  let fo_do_comments = s:HasFormatOptions("q")
  let second_indent = a:second_indent

  " save the original option's value
  let formatoptions_save = &formatoptions
  let iskeyword_save = &iskeyword

  let leader_width = s:GetLeader("get_leader_width")

  " When fo_do_comments is TRUE, set formatoptions value so that the comment
  " leader is set for next line.
  if fo_do_comments
    set formatoptions+=r
  else
    set formatoptions-=r
  endif

  " Set iskeyword option value to every printable ascii characters, so that
  " "w" can stop at only multibyte-ascii boundary or white space.
  set iskeyword="!-~"

  call s:SetCursor(line("."), textwidth)
  let no_begin = s:GetOption('format_no_begin')
  let no_end = s:GetOption('format_no_end')
  while s:GetWidth() > virtcol(".")
    let finish_format = 0
    let force_fold = 0
    let do_insert = 0
    let max_width = textwidth + s:GetOption('format_allow_over_tw')

    let ch = s:GetCharUnderCursor()

    " English word folding
    if ch =~ "[!-~]\\{1}" && s:GetCharNextCursor() =~ "[!-~]\\{1}"
      call s:MoveToWordBegin()
      if virtcol(".") - 1 > leader_width
        " move to previous word end
        normal! ge
      endif
    endif

    " Skip white spaces
    if ch =~ "\\s"
      while ch =~ "\\s" && virtcol(".") - 1 > leader_width
        normal! h
        let ch = s:GetCharUnderCursor()
      endwhile
      let force_fold = 1
    endif

    if virtcol(".") - 1 <= leader_width
      call s:MoveToFirstWordEnd(leader_width)
      let force_fold = 1
      if s:GetWidth() == virtcol(".")
        let finish_format = 1
      endif
    endif

    " Taboo rule
    if !finish_format && !force_fold && g:format_follow_taboo_rule
      let next_ch = s:GetCharNextCursor()
      if s:IsTaboo(next_ch, no_begin)
        normal! l
        while s:IsTaboo(next_ch, no_begin)
          " if cursor is at the line end, break.
          if s:GetWidth() == virtcol(".")
            let finish_format = 1
            break
          endif
          normal! l
          let next_ch = s:GetCharUnderCursor()
        endwhile
        if !finish_format
          normal! h
        endif
      endif

      let ch = s:GetCharUnderCursor()
      if virtcol(".") > max_width
        let finish_format = 0
        while s:IsTaboo(ch, no_begin) && virtcol(".") - 1 > leader_width
          normal! h
          let ch = s:GetCharUnderCursor()
        endwhile
        if ch =~ "[!-~]\\{1}"
          call s:MoveToWordBegin()
          if virtcol(".") - 1 > leader_width
            normal! ge
          else
            call s:MoveToFirstWordEnd(leader_width)
            let force_fold = 1
          endif
        else
          let do_insert = 1
        endif
      endif

      let ch = s:GetCharUnderCursor()
      if s:IsTaboo(ch, no_end) && !force_fold
        let do_insert = 0
        let @b = no_end
        while s:IsTaboo(ch, no_end) && virtcol(".") -1 > leader_width
          normal! h
          let ch = s:GetCharUnderCursor()
        endwhile
        if virtcol(".") -1 <= leader_width
          call s:MoveToFirstWordEnd(leader_width)
        endif
      endif
    endif

    if finish_format
      break
    endif

    if do_insert
      call s:InsertNewLine()
    else
      call s:AppendNewLine()
    endif

    if do_second_indent && second_indent != "default"
      call setline(line("."), second_indent . substitute(getline("."), "^\\s*", "", ""))
      let do_second_indent = 0
      if strlen(second_indent) > 0
        normal! h
      endif
    endif

    if virtcol(".") == 1
      let leader_width = 0
    else
      let leader_width = virtcol(".")
    endif

    call s:SetCursor(line("."), textwidth)
  endwhile

  execute "set formatoptions=" . formatoptions_save
  execute "set iskeyword=" . iskeyword_save
endfunction

"
" GetLeader(...)
"   Get the comment leader string from current line. If argument
"   is specified, then return the comment leader width. Note that
"   returned comment leader and the current line's comment leader is
"   not always same.
"
function! s:GetLeader(...)
  if !s:HasFormatOptions('q')
    if a:0 == 1
      return 0
    endif
    return ""
  endif

  let col_save = virtcol(".")

  let formatoptions_save = &formatoptions
  let autoindent_save = &autoindent
  let cindent_save = &cindent
  let smartindent_save = &smartindent
  set formatoptions+=o
  set autoindent
  set nocindent
  set nosmartindent

  execute "normal! ox\<ESC>\"_x"

  if a:0 == 1
    if getline(".") =~ "^$"
      let leader_width = 0
    else
      let leader_width = virtcol(".")
    endif
  endif

  let leader = getline(".")

  if line(".") == line("$")
    normal! "_dd
  else
    normal! "_ddk
  endif

  execute "set formatoptions=" . formatoptions_save
  if !autoindent_save
    set noautoindent
  endif
  if cindent_save
    set cindent
  endif
  if smartindent_save
    set smartindent
  endif

  execute "normal! " . col_save . "|"

  if a:0 == 1
    return leader_width
  else
    return leader
  endif
endfunction

"
" FmtCheckPar(leader)
"   Blank lines, lines containing only white space or the comment leader,
"   are left untouched by the formatting. The function returns true in this
"   case.
"
function! s:FmtCheckPar(leader)
  let three_start = substitute(&com, '.*s[^:]*:\([^,]*\),.*', '\1', '')
  let three_end = substitute(&com, '.*e[^:]*:\([^,]*\),.*', '\1', '')
  let line = substitute(getline("."), "\\s*$", "", "")
  let line = substitute(line, "^\\s*", "", "")
  let leader = substitute(a:leader, "\\s*$", "", "")
  let leader = substitute(leader, "^\\s*", "", "")
  if line == three_start || line == three_end
    return 1
  endif
  return line == leader
endfunction

"
" SameLeader(leader1, leader2)
"   Return true if the two comment leaders given are the same. White-space is
"   ignored.
"
function! s:SameLeader(leader1, leader2)
  if g:format_indent_sensitive
    return a:leader1 == a:leader2
  else
    return substitute(a:leader1, "\\s\\+$", "", "") == substitute(a:leader2, "\\s\\+$", "", "")
  endif
endfunction

"
" SetCursor(lnum, width)
"   Set cursor to the line number, then move the cursor to within the width
"   and the most right virtual column.
"
function! s:SetCursor(lnum, ...)
  call cursor(a:lnum, 0)
  if a:0 >= 1
    execute "normal! " . a:1 . "|"
    if a:1 > 2 && virtcol(".") > a:1
      normal! h
    endif
  endif
endfunction

"
" HasFormatOptions(x)
"   Return true if format option 'x' is in effect. Take care of no
"   formatting when 'paste' is set.
"
function! s:HasFormatOptions(x)
  if &paste || (a:x == "2" && !&autoindent) || (a:x == "2" && g:format_indent_sensitive)
    return 0
  endif
  return &formatoptions =~ a:x
endfunction

"
" DoRangeJoin(next_leader)
"   DoJoin driver, able to support range.
"
function! s:DoRangeJoin(next_leader) range
  if  count > 2
    let repeat = count - 1
  else
    let repeat = 1
  endif
  while repeat
    call s:DoJoin(a:next_leader)
    let repeat = repeat - 1
  endwhile
endfunction

"
" DoJoin(next_leader)
"   Join line and next line. The comment leader will be removed.
"
function! s:DoJoin(next_leader)
  if line(".") == line("$")
    return
  endif
  let showcmd_save = &showcmd
  set noshowcmd
  let wrap_save = &wrap
  set nowrap
  let lazyredraw_save = &lazyredraw
  set lazyredraw

  normal! $
  let end_char = s:GetCharUnderCursor()

  if s:HasFormatOptions("q") && a:next_leader != ""
    let next_leader = escape(a:next_leader, '^.*\$~[]')
    let next_leader = "^" . substitute(next_leader, "\\s*$", "", "")
    normal! j0
    if getline(".") =~ next_leader
      call setline(line("."), substitute(getline("."), next_leader, "", ""))
    else
      let leader_width = s:GetLeader("get_leader_width")
      let i = leader_width + 1
      execute "normal! 0\"_d" . i . "|"
    endif
    normal! k
  endif

  normal! J

  if wrap_save
    set wrap
  endif
  if !lazyredraw_save
    set nolazyredraw
  endif
  if showcmd_save
    set showcmd
  endif
endfunction

"
" DoJoinRange(start_lnum, end_lnum)
"   Join lines from start_lnum to end_lnum, according to the
"   "$fomrat_join_spaces"
"
function! s:DoJoinRange(start_lnum, end_lnum)
  let count_nr = a:end_lnum - a:start_lnum
  call s:SetCursor(a:start_lnum)
  while count_nr > 0
    call s:DoJoin("")
    let count_nr = count_nr - 1
  endwhile
endfunction

"
" GetWidth()
"   Return the current line width. If the line is empty returns 0. Note that
"   if the character at the line end is a multibyte character, this returns
"   real width minus 1, same as virtcol().
"
function! s:GetWidth()
  return virtcol("$") - 1
endfunction

"
" GetCharUnderCursor()
"   Get (multibyte) character under current cursor.
"
function! s:GetCharUnderCursor()
  return matchstr(getline("."), ".", col(".") - 1)
endfunction

" Get a character at column next cursor.
function! s:GetCharNextCursor()
  return matchstr(getline("."), '.\@<=.', col(".") - 1)
endfunction

function! s:GetCharPrevCursor()
  let pat = '.\%' . col('.') . 'c'
  return matchstr(getline('.'), pat)
endfunction

"
" AppendNewLine()
"   Insert newline after cursor.
"
function! s:AppendNewLine()
  execute "normal! a\<CR>\<ESC>"
endfunction

"
" InsertNewLine()
"   Insert newline before cursor.
"
function! s:InsertNewLine()
  execute "normal! i\<CR>\<ESC>"
endfunction

"
" MoveToWordEnd()
"   Move to the word end.
"
function! s:MoveToWordEnd()
  if line(".") == 1
    normal! wge
  else
    normal! gee
  endif
endfunction

"
" MoveToWordBegin()
"   Move to the word begin.
"
function! s:MoveToWordBegin()
  if line(".") == 1
    normal! wb
  else
    normal! gew
  endif
endfunction

"
" MoveToFirstWordEnd()
"   Move to the first word end after the comment leader.
"
function! s:MoveToFirstWordEnd(leader_width)
  let i = a:leader_width + 1
  execute "normal! " . i . "|"
  call s:MoveToWordEnd()
endfunction

"
" IsTaboo(char, taboo_rule_list)
"   Return true when the character matches one of taboo_rule_list
"
function! s:IsTaboo(char, taboo_rule_list)
  return match(a:taboo_rule_list, '\V'.escape(a:char, '\')) >= 0
endfunction

" Get option value.  Priority is window-local > buffer-local > global.
function! s:GetOption(name)
  let var = getwinvar(winnr(), a:name)
  if var == ''
    let var = getbufvar(bufnr('%'), a:name)
    if var == ''
      let var = g:{a:name}
    endif
  endif
  return var
endfunction

function! s:Feedkeys(string, mode, count)
  let i = 0
  while i < a:count
    let i += 1
    call feedkeys(a:string, a:mode)
  endwhile
endfunction

function! s:GetLinebreakOffset(curr_line, curr_col)
  " 禁則ルールに基づいて、カーソル位置の調整を行う
  " ぶら下がりは考慮しない
  let back_count = 0
  let no_begin = s:GetOption('format_no_begin')
  let no_end = s:GetOption('format_no_end')
  let curr_char = matchstr(a:curr_line, '\%'.a:curr_col.'c.')
  let back_col = 0
  while 1
    let prev_char = matchstr(a:curr_line, '.\%'.(a:curr_col - back_col).'c')
    if curr_char == ''
      let back_count = 0
      break
    elseif s:IsTaboo(curr_char, no_begin) || s:IsTaboo(prev_char, no_end)
      let back_count += 1
      let curr_char = prev_char
      let back_col += strlen(curr_char)
    else
      break
    endif
  endwhile
  return back_count
endfunction

function! Format_Japanese()
  if mode() == 'n'
    call s:Format(v:lnum, v:lnum + v:count - 1)
    return 0
  elseif s:HasFormatOptions('a')
    " Too difficult to implement.
    return 1
  else
    let curcol = col('.')
    " v:charを入力した後で&textwidthを超える場合に改行位置の補正を行う
    let new_line = getline('.') . v:char
    if curcol + strlen(v:char) > &textwidth
      let back_count = s:GetLinebreakOffset(new_line, curcol)
      " カーソル移動と改行の挿入を行う
      if back_count > 0
        " 本関数終了後に入力されるv:char分も考慮に入れる
        let l:count = back_count + 1
        call s:Feedkeys("\<LEFT>", 'n', l:count)
        call feedkeys("\<CR>", 'n')
        call s:Feedkeys("\<RIGHT>", 'n', l:count)
        return 0
      else
        return 1
      endif
    else
      return 1
    endif
  endif
endfunction

set formatexpr=Format_Japanese()
