" vim:ts=8 sts=2 sw=2 tw=0 nowrap:
"
" memo.vim - メモ用シンタックス定義
"
" Language:	memo
" Maintainer:	MURAOKA Taro <koron.kaoriya@gmail.com>
" Last Change:	18-Jan-2013.

scriptencoding cp932

syntax match memoLabel display "^\%>1l\k\+\>"
syntax match memoLabelUpper display "^[A-Z]\+\>\(\s\|\d\|$\)"
syntax match memoLabelDate display "^\d\+-\k\+-\d\+\(\.\)\="
syntax match memoLabelSquare display "^\s*[■□◆◇]"hs=e-1
syntax match memoLabelRound display "^\s*[○●◎〇]"hs=e-1
syntax match memoLabelParenthesis display "\(^\s*\)\@<=([^)]*)"
syntax match memoLabelWarning display "注意:"
"syntax match memoLabelNote display "補足:"he=e-1

syntax match memoTitle display "\%1l.*"
syntax match memoDate display "\<\([012]\d\|3[01]\)-\k\+-\d\+\(\.\)\="
syntax match memoUrl display "\(https\=\|ftp\):[-!#%&+,./0-9:;=?@A-Za-z_~]\+"

syntax match memoListItem display "^\s*[-+*]\s\+\S.*$"
syntax match memoListOrderedItem display "^\s*\d\+[.):]\s\+\S.*$"

syntax match memoComment display '^\s*#\s\+\S.*$'
syntax match memoCommentTitle display '^\s*\u\a*\(\s\+\u\a*\)*:'
syntax match memoCommentVim display '^\s*vi\(m\)\=:[^:]*:'


hi def link memoLabel			Statement
hi def link memoLabelUpper		Todo
hi def link memoLabelDate		Todo
hi def link memoLabelSquare		Comment
hi def link memoLabelRound		WarningMsg
hi def link memoLabelWarning		Error
hi def link memoLabelParenthesis	Special

hi def link memoTitle			Title
hi def link memoDate			Constant
hi def link memoUrl			Underlined

hi def link memoListItem		Identifier
hi def link memoListOrderedItem		Identifier

hi def link memoComment			Comment
hi def link memoCommentTitle		PreProc
hi def link memoCommentVim		PreProc

let b:current_syntax = "memo"
