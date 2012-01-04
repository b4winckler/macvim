" vi:set ts=8 sts=2 sw=2 tw=0:
"
" autodate.vim - A plugin to update time stamps automatically
"
" Maintainer:	MURAOKA Taro <koron.kaoriya@gmail.com>
" Last Change:	06-Feb-2006.

" Description:
" Command:
"   :Autodate	    Manually autodate.
"   :AutodateON	    Turn on autodate in current buffer (default).
"   :AutodateOFF    Turn off autodate in current buffer.
"
" Options:
"   Each global variable (option) is overruled by buffer variable (what
"   starts with "b:").
"
"   'autodate_format'
"	Format string used for time stamps.  See |strftime()| for details.
"	See MonthnameString() for special extension of format.
"	Default: '%d-%3m-%Y'
"
"   'autodate_lines'
"	The number of lines searched for the existence of a time stamp when
"	writing a buffer.  The search range will be from top of buffer (or
"	line 'autodate_start_line') to 'autodate_lines' lines below.  The
"	bigger value you have, the longer it'll take to search words.  You
"	can expect to improve performance by decreasing the value of this
"	option.
"	Default: 50
"
"   'autodate_start_line'
"	Line number to start searching for time stamps when writing buffer
"	to file.
"	If minus, line number is counted from the end of file.
"	Default: 1
"
"   'autodate_keyword_pre'
"	A prefix pattern (see |pattern| for details) which denotes time
"	stamp's location.  If empty, default value will be used.
"	Default: '\cLast Change:'
"
"   'autodate_keyword_post'
"	A postfix pattern which denotes time stamp's location.  If empty,
"	default value will be used.
"	Default: '\.'
"
" Usage:
"   Write a line as below (case ignored) somewhere in the first 50 lines of
"   a buffer:
"	Last Change: .
"   When writing the buffer to a file, this line will be modified and a time
"   stamp will be inserted automatically.  Example:
"	Last Change: 11-May-2002.
"
"   You can execute :Autodate command to update time stamps manually.  The
"   range of lines which looks for a time stamp can also be specified.  When
"   no range is given, the command will be applied to the current line.
"   Example:
"	:%Autodate		" Whole file
"	:\<,\>Autodate		" Range selected by visual mode
"	:Autodate		" Current cursor line
"
"   The format of the time stamp to insert can be specified by
"   'autodate_format' option.  See |strftime()| (vim script function) for
"   details.  Sample format settings and the corresponding outputs are show
"   below.
"	FORMAT: %Y/%m/%d	OUTPUT: 2001/12/24
"	FORMAT: %H:%M:%S	OUTPUT: 10:06:32
"	FORMAT: %y%m%d-%H%M	OUTPUT: 011224-1006
"
"   Autodate.vim determines where to insert a time stamp by looking for a
"   KEYWORD.  A keyword consists of a PREFIX and a POSTFIX part, and they
"   can be set by 'autodate_keyword_pre' and 'autodate_keyword_post'
"   options, respectively.  If you set these values as below in your .vimrc:
"	:let autodate_format = ': %Y/%m/%d %H:%M:%S '
"	:let autodate_keyword_pre  = '\$Date'
"	:let autodate_keyword_post = '\$'
"   They will function like $Date$ in cvs.  Example:
"	$Date: 2001/12/24 10:06:32 $
"
"   Just another application. To insert a time stamp between '<!--DATE-->'
"   when writing HTML, try below:
"	:let b:autodate_keyword_pre = '<!--DATE-->'
"	:let b:autodate_keyword_post = '<!--DATE-->'
"   It will be useful if to put these lines in your ftplugin/html.vim.
"   Example:
"	<!--DATE-->24-Dec-2001<!--DATE-->
"
"   In addition, priority is given to a buffer local option (what starts in
"   b:) about all the options of autodate.
"
"
" To make vim NOT TO LOAD this plugin, write next line in your .vimrc:
"	:let plugin_autodate_disable = 1

" Japanese Description:
" コマンド:
"   :Autodate	    手動でタイムスタンプ更新
"   :AutodateON	    現在のバッファの自動更新を有効化
"   :AutodateOFF    現在のバッファの自動更新を無効化
"
" オプション: (それぞれのオプションはバッファ版(b:)が優先される)
"
"   'autodate_format'
"	タイムスタンプに使用されるフォーマット文字列。フォーマットの詳細は
"	|strftime()|を参照。フォーマットへの独自拡張についてはMonthnameString()
"	を参照。省略値: '%d-%3m-%Y'
"
"   'autodate_lines'
"	保存時にタイムスタンプの存在をチェックする行数。増やせば増やすほど
"	キーワードを検索するために時間がかかり動作が遅くなる。逆に遅いと感じ
"	たときには小さな値を設定すればパフォーマンスの改善が期待できる。
"	省略値: 50
"
"   'autodate_keyword_pre'
"	タイムスタンプの存在を示す前置キーワード(正規表現)。必須。空文字列を
"	指定すると省略値が使われる。省略値: '\cLast Change:'
"
"   'autodate_keyword_post'
"	タイムスタンプの存在を示す後置キーワード(正規表現)。必須。空文字列を
"	指定すると省略値が使われる。省略値: '\.'
"
" 使用法:
"   ファイルの先頭から50行以内に
"	Last Change: .
"   と書いた行(大文字小文字は区別しません)を用意すると、ファイルの保存(:w)時
"   に自動的にその時刻(タイムスタンプ)が挿入されます。結果例:
"	Last Change: 11-May-2002.
"
"   Exコマンドの:Autodateを実行することで手動でタイムスタンプの更新が行なえ
"   ます。その際にタイムスタンプを探す範囲を指定することもできます。特に範囲
"   を指定しなければカーソルのある行が対象になります。例:
"	:%Autodate		" ファイル全体
"	:\<,\>Autodate		" ビジュアル選択領域
"	:Autodate		" 現在カーソルのある行
"
"   挿入するタイムスタンプの書式はオプション'autodate_format'で指定すること
"   ができます。詳細はVimスクリプト関数|strftime()|の説明に従います。以下に
"   書式とその出力の例を示します:
"	書式: %Y/%m/%d		出力: 2001/12/24
"	書式: %H:%M:%S		出力: 10:06:32
"	書式: %y%m%d-%H%M	出力: 011224-1006
"
"   autodate.vimはキーワードを探すことでタイムスタンプを挿入すべき位置を決定
"   しています。キーワードは前置部と後置部からなり、それぞれオプションの
"   'autodate_keyword_pre'と'autodate_keyword_post'を設定することで変更でき
"   ます。個人設定ファイル(_vimrc)で次のように設定すると:
"	:let autodate_format = ': %Y/%m/%d %H:%M:%S '
"	:let autodate_keyword_pre  = '\$Date'
"	:let autodate_keyword_post = '\$'
"   cvsにおける$Date$のように動作します。例:
"	$Date: 2001/12/24 10:06:32 $
"
"   応用としてHTMLを記述する際に<!--DATE-->で囲まれた中にタイムスタンプを挿
"   入させたい場合には:
"	:let b:autodate_keyword_pre = '<!--DATE-->'
"	:let b:autodate_keyword_post = '<!--DATE-->'
"   と指定します。ftplugin/html.vimで設定すると便利でしょう。例:
"	<!--DATE-->24-Dec-2001<!--DATE-->
"
"   なおautodateの総てのオプションについて、バッファローカルオプション(b:で
"   始まるもの)が優先されます。
"
" このプラグインを読込みたくない時は.vimrcに次のように書くこと:
"	:let plugin_autodate_disable = 1

if exists('plugin_autodate_disable')
  finish
endif
let s:debug = 0

"---------------------------------------------------------------------------
"				    Options

"
" 'autodate_format'
"
if !exists('autodate_format')
  let g:autodate_format = '%d-%3m-%Y'
endif

"
" 'autodate_lines'
"
if !exists('autodate_lines')
  let g:autodate_lines = 50
endif

"
" 'autodate_start_line'
"
if !exists('autodate_start_line')
  let g:autodate_start_line = 1
endif

"
" 'autodate_keyword_pre'
"
if !exists('autodate_keyword_pre')
  let g:autodate_keyword_pre = '\cLast Change:'
endif

"
" 'autodate_keyword_post'
"
if !exists('autodate_keyword_post')
  let g:autodate_keyword_post = '\.'
endif

"---------------------------------------------------------------------------
"				    Mappings

command! -range Autodate call <SID>Autodate(<line1>, <line2>)
command! AutodateOFF let b:autodate_disable = 1
command! AutodateON let b:autodate_disable = 0
if has("autocmd")
  augroup Autodate
    au!
    autocmd BufUnload,FileWritePre,BufWritePre * call <SID>Autodate()
  augroup END
endif " has("autocmd")

"---------------------------------------------------------------------------
"				 Implementation

"
" Autodate([{firstline} [, {lastline}]])
"
"   {firstline}と{lastline}で指定された範囲について、タイムスタンプの自動
"   アップデートを行なう。{firstline}が省略された場合はファイルの先頭、
"   {lastline}が省略された場合は{firstline}から'autodate_lines'行の範囲が対
"   象になる。
"
function! s:Autodate(...)
  " Check enable
  if (exists('b:autodate_disable') && b:autodate_disable != 0) || &modified == 0
    return
  endif

  " Verify {firstline}
  if a:0 > 0 && a:1 > 0
    let firstline = a:1
  else
    let firstline = s:GetAutodateStartLine()
  endif

  " Verify {lastline}
  if a:0 > 1 && a:2 <= line('$')
    let lastline = a:2
  else
    let lastline = firstline + s:GetAutodateLines() - 1
    " Range check
    if lastline > line('$')
      let lastline = line('$')
    endif
  endif

  if firstline <= lastline
    call s:AutodateStub(firstline, lastline)
  endif
endfunction

"
" GetAutodateStartLine()
"
"   探索開始点を取得する
"
function! s:GetAutodateStartLine()
  let retval = 1
  if exists('b:autodate_start_line')
    let retval = b:autodate_start_line
  elseif exists('g:autodate_start_line')
    let retval = g:autodate_start_line
  endif

  if retval < 0
    let retval = retval + line('$') + 1
  endif
  if retval <= 0
    let retval = 1
  endif
  return retval
endfunction

"
" GetAutodateLines()
"   
"   autodate対象範囲を取得する
"
function! s:GetAutodateLines()
  if exists('b:autodate_lines') && b:autodate_lines > 0
    return b:autodate_lines
  elseif exists('g:autodate_lines') && g:autodate_lines > 0
    return g:autodate_lines
  else
    return 50
  endif
endfunction

"
" AutodateStub(first, last)
"
"   指定された範囲についてタイムスタンプの自動アップデートを行なう。
"
function! s:AutodateStub(first, last)

  " Verify pre-keyword.
  if exists('b:autodate_keyword_pre') && b:autodate_keyword_pre != ''
    let pre = b:autodate_keyword_pre
  else
    if exists('g:autodate_keyword_pre') && g:autodate_keyword_pre != ''
      let pre = g:autodate_keyword_pre
    else
      let pre = '\cLast Change:'
    endif
  endif

  " Verify post-keyword.
  if exists('b:autodate_keyword_post') && b:autodate_keyword_post != ''
    let post = b:autodate_keyword_post
  else
    if exists('g:autodate_keyword_post') && g:autodate_keyword_post != ''
      let post = g:autodate_keyword_post
    else
      let post = '\.'
    endif
  endif

  " Verify format.
  if exists('b:autodate_format') && b:autodate_format != ''
    let format = b:autodate_format
  else
    if exists('g:autodate_format') && g:autodate_format != ''
      let format = g:autodate_format
    else
      let format = '%d-%3m-%Y'
    endif
  endif

  " Generate substitution pattern
  let pat = '\('.pre.'\s*\)\(\S.*\)\?\('.post.'\)'
  let sub = Strftime2(format)
  " For debug
  if s:debug
    echo "range=".a:first."-".a:last
    echo "pat= ".pat
    echo "sub= ".sub
  endif

  " Process
  let i = a:first
  while i <= a:last
    let curline = getline(i)
    if curline =~ pat
      let newline = substitute(curline, pat, '\1' . sub . '\3', '')
      if curline !=# newline
	call setline(i, newline)
      endif
    endif
    let i = i + 1
  endwhile
endfunction

"
" Strftime2({format} [, {time}])
"   Enchanced version of strftime().
"
"   strftime()のフォーマット拡張バージョン。フォーマット書式はほとんどオリジ
"   ナルと一緒。しかし月の英語名に置換わる特別な書式 %{n}m が使用可能。{n}に
"   は英語名の文字列の長さを指定する(最大9)。0を指定すれば余分な空白は付加さ
"   れない。
"	例:
"	    :echo Strftime2("%d-%3m-%Y")
"	    07-Oct-2001
"	    :echo Strftime2("%d-%0m-%Y")
"	    07-October-2001
"
function! Strftime2(...)
  if a:0 > 0
    " Get {time} argument.
    if a:0 > 1
      let time = a:2
    else
      let time = localtime()
    endif
    " Parse special format.
    let format = a:1
    let format = substitute(format, '%\(\d\+\)m', '\=MonthnameString(-1, submatch(1), time)', 'g')
    let format = substitute(format, '%\(\d\+\)a', '\=DaynameString(-1, submatch(1), time)', 'g')
    return strftime(format, time)
  endif
  " Genrate error!
  return strftime()
endfunction

"
" MonthnameString([{month} [, {length} [, {time}]]])
"   Get month name string in English with first specified letters.
"
"   英語の月名を指定した長さで返す。{month}を省略した場合には現在の月名が返
"   される。{month}に無効な指定(1～12以外)が行なわれた場合は{time}で示される
"   月名が返される。{time}を省略した場合には代わりに|localtime()|が使用され
"   る。{length}には返す名前の長さを指定するが省略すると任意長になる。
"	例:
"	    :echo MonthnameString(8) . " 2001"
"	    August 2001
"	    :echo MonthnameString(8,3) . " 2001"
"	    Aug 2001
"
function! MonthnameString(...)
  " Get {time} argument.
  if a:0 > 2
    let time = a:3
  else
    let time = localtime()
  endif
  " Verify {month}.
  if a:0 > 0 && (a:1 >= 1 && a:1 <= 12)
    let month = a:1
  else
    let month = substitute(strftime('%m', time), '^0\+', '', '')
  endif
  " Verify {length}.
  if a:0 > 1 && (a:2 >= 1 && a:2 <= 9)
    let length = a:2
  else
    let length = strpart('785534469788', month - 1, 1)
  endif
  " Generate string of month name.
  return strpart('January  February March    April    May      June     July     August   SeptemberOctober  November December ', month * 9 - 9, length)
endfunction

"
" DaynameString([{month} [, {length} [, {time}]]])
"   Get day name string in English with first specified letters.
"
"   英語の曜日名を指定した長さで返す。{day}を省略した場合には本日の曜日名が
"   返される。{day}に無効な指定(0～6以外)が行なわれた場合は{time}で示される
"   曜日名が返される。{time}を省略した場合には代わりに|localtime()|が使用さ
"   れる。{length}には返す名前の長さを指定するが省略すると任意長になる。
"	例:
"	    :echo DaynameString(0)
"	    Sunday
"	    :echo DaynameString(5,3).', 13th'
"	    Fri, 13th
"
function! DaynameString(...)
  " Get {time} argument.
  if a:0 > 2
    let time = a:3
  else
    let time = localtime()
  endif
  " Verify {day}.
  if a:0 > 0 && (a:1 >= 0 && a:1 <= 6)
    let day = a:1
  else
    let day = strftime('%w', time) + 0
  endif
  " Verify {length}.
  if a:0 > 1 && (a:2 >= 1 && a:2 <= 9)
    let length = a:2
  else
    let length = strpart('6798686', day, 1)
  endif
  " Generate string of day name.
  return strpart('Sunday   Monday   Tuesday  WednesdayThursday Friday   Saturday ', day * 9, length)
endfunction
