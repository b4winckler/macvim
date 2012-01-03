" vim:set ts=8 sts=2 sw=2 tw=0 nowrap:
"
" hz_ja.vim - Convert character between HANKAKU and ZENKAKU
"
" Last Change: 06-Feb-2006.
" Written By:  MURAOKA Taro <koron.kaoriya@gmail.com>
"
" Commands:
"   :Hankaku	  Convert to HANKAKU.
"   :Zenkaku	  Convert to ZENKAKU.
"   :ToggleHZ	  Toggole convert between HANKAKU and ZENKAKU.
"
" Functions:
"   ToHankaku(str)	Convert given string to HANKAKU.
"   ToZenkaku(str)	Convert given string to ZENKAKU.
"
" To make vim DO NOT LOAD this plugin, write next line in your .vimrc:
"	:let plugin_hz_ja_disable = 1

" Japanese Description:
" コマンド:
"   :[raneg]Hankaku
"   :[range]Zenkaku
"   :[range]ToggleHZ
"   :[range]HzjaConvert {target}
"
" キーマッピング:
"   以下はビジュアル選択領域に対する操作です。また()内はHzjaConvertコマンド
"   と関数に渡す、targetに指定可能な文字列です。
"     gHL	可能な文字を全て半角に変換する	(han_all)
"     gZL	可能な文字を全て全角に変換する	(zen_all)
"     gHA	ASCII文字を全て半角に変換する	(han_ascii)
"     gZA	ASCII文字を全て全角に変換する	(zen_ascii)
"     gHM	記号を全て半角に変換する	(han_kigou)
"     gZM	記号を全て全角に変換する	(zen_kigou)
"     gHW	英数字を全て半角に変換する	(han_eisu)
"     gZW	英数字を全て全角に変換する	(zen_eisu)
"     gHJ	カタカナを全て半角に変換する	(han_kana)
"     gZJ	カタカナを全て全角に変換する	(zen_kana)
"   以下は使用頻度の高さを考慮して、上記と重複した機能として割り当てられた
"   キーマップです。
"     gHH	ASCII文字を全て半角に変換する	(han_ascii)
"     gZZ	カタカナを全て全角に変換する	(zen_kana)
" 
" 関数:
"   ToHankaku(str)	文字列を半角へ変換する
"   ToZenkaku(str)	文字列を全角へ変換する
"   HzjaConvert(str, target)
"			文字列をtargetに従い変換する。targetの意味はキーマッ
"			ピングの項目を参照。
"
" メニュー拡張:
"   GUI環境ではビジュアル選択時のポップアップメニュー(右クリックメニュー)に
"   変換用のコマンドが追加されます。
"
" このプラグインを読込みたくない時は.vimrcに次のように書くこと:
"	:let plugin_hz_ja_disable = 1

scriptencoding cp932

if exists('plugin_hz_ja_disable')
  finish
endif
if !has('multi_byte')
  finish
endif

command! -nargs=0 -range Hankaku <line1>,<line2>call <SID>ToggleLineWise('Hankaku')
command! -nargs=0 -range Zenkaku <line1>,<line2>call <SID>ToggleLineWise('Zenkaku')
command! -nargs=0 -range ToggleHZ <line1>,<line2>call <SID>ToggleLineWise('Toggle')
command! -nargs=1 -range -complete=custom,HzjaConvertComplete HzjaConvert <line1>,<line2>call <SID>HzjaConvert(<q-args>)

vnoremap <silent> gHL <C-\><C-N>:call <SID>HzjaConvertVisual('han_all')<CR>
vnoremap <silent> gZL <C-\><C-N>:call <SID>HzjaConvertVisual('zen_all')<CR>
vnoremap <silent> gHA <C-\><C-N>:call <SID>HzjaConvertVisual('han_ascii')<CR>
vnoremap <silent> gZA <C-\><C-N>:call <SID>HzjaConvertVisual('zen_ascii')<CR>
vnoremap <silent> gHM <C-\><C-N>:call <SID>HzjaConvertVisual('han_kigou')<CR>
vnoremap <silent> gZM <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kigou')<CR>
vnoremap <silent> gHW <C-\><C-N>:call <SID>HzjaConvertVisual('han_eisu')<CR>
vnoremap <silent> gZW <C-\><C-N>:call <SID>HzjaConvertVisual('zen_eisu')<CR>
vnoremap <silent> gHJ <C-\><C-N>:call <SID>HzjaConvertVisual('han_kana')<CR>
vnoremap <silent> gZJ <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kana')<CR>

vnoremap <silent> gHH <C-\><C-N>:call <SID>HzjaConvertVisual('han_ascii')<CR>
vnoremap <silent> gZZ <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kana')<CR>

if has('gui_running')
  vnoremenu 1.120 PopUp.-SEP3-	<Nop>
  vnoremenu 1.130.100 PopUp.全角→半角(&H).全部(&L) <C-\><C-N>:call <SID>HzjaConvertVisual('han_all')<CR>
  vnoremenu 1.130.110 PopUp.全角→半角(&H).ASCII(&A) <C-\><C-N>:call <SID>HzjaConvertVisual('han_ascii')<CR>
  vnoremenu 1.130.120 PopUp.全角→半角(&H).記号(&M) <C-\><C-N>:call <SID>HzjaConvertVisual('han_kigou')<CR>
  vnoremenu 1.130.130 PopUp.全角→半角(&H).英数(&W) <C-\><C-N>:call <SID>HzjaConvertVisual('han_eisu')<CR>
  vnoremenu 1.130.140 PopUp.全角→半角(&H).カタカナ(&J) <C-\><C-N>:call <SID>HzjaConvertVisual('han_kana')<CR>
  vnoremenu 1.140.100 PopUp.半角→全角(&Z).全部(&L) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_all')<CR>
  vnoremenu 1.140.110 PopUp.半角→全角(&Z).ASCII(&A) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_ascii')<CR>
  vnoremenu 1.140.120 PopUp.半角→全角(&Z).記号(&M) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kigou')<CR>
  vnoremenu 1.140.130 PopUp.半角→全角(&Z).英数(&W) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_eisu')<CR>
  vnoremenu 1.140.140 PopUp.半角→全角(&Z).カタカナ(&J) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kana')<CR>
endif

function! HzjaConvertComplete(argleand, cmdline, curpos)
  call s:Initialize()
  return s:targetlist
endfunction

function! s:HzjaConvert(target) range
  let nline = a:firstline
  while nline <= a:lastline
    call setline(nline, HzjaConvert(getline(nline), a:target))
    let nline = nline + 1
  endwhile
endfunction

" 与えられた文字列の半角全角文字を相互に変換する。変換の方法は引数targetで文
" 字列として指定する。指定できる文字列は以下のとおり。
"
"   han_all	全ての全角文字→半角
"   han_ascii	全角アスキー→半角
"   han_kana	全角カタカナ→半角
"   han_eisu	全角英数→半角
"   han_kigou	全角記号→半角
"   zen_all	全ての半角文字→全角
"   zen_ascii	半角アスキー→全角
"   zen_kana	半角カタカナ→全角
"   zen_eisu	半角英数→全角
"   zen_kigou	半角記号→全角
"
function! HzjaConvert(line, target)
  call s:Initialize()
  if !exists('s:mx_'.a:target)
    return a:line
  else
    let mode = a:target =~# '^han_' ? 'Hankaku' : 'Zenkaku'
    return substitute(a:line, s:mx_{a:target}, '\=s:ToggleLine(submatch(0),0,0,mode)', 'g')
  endif
endfunction

function! s:HzjaConvertVisual(target)
  call s:Initialize()
  let save_regcont = @"
  let save_regtype = getregtype('"')
  normal! gvy
  call setreg('"', HzjaConvert(@", a:target), getregtype('"'))
  normal! gvp
  call setreg('"', save_regcont, save_regtype)
endfunction

let s:init = 0
function! s:Initialize()
  if s:init != 0
    return
  endif
  let s:init = 1

  let s:match_character = '\%([ｳｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾊﾋﾌﾍﾎ]ﾞ\|[ﾊﾋﾌﾍﾎ]ﾟ\|.\)'
  let s:match_hankaku = '\%([ｳｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾊﾋﾌﾍﾎ]ﾞ\|[ﾊﾋﾌﾍﾎ]ﾟ\|[ -~｡｢｣､ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ]\)'

  let zen_ascii = '　！”＃＄％＆’（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［￥］＾＿‘ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～'
  let zen_kana = '。「」、ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜ヴガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ'
  let han_ascii = " !\"#$%&'()*+,\\-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
  let han_kana = '｡｢｣､ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ'
  let s:mx_han_all = "[".zen_ascii.zen_kana."]\\+"
  let s:mx_zen_all = "[".han_ascii.han_kana."]\\+"
  let s:mx_han_ascii = "[".zen_ascii."]\\+"
  let s:mx_zen_ascii = "[".han_ascii."]\\+"
  let s:mx_han_kana = "[".zen_kana."]\\+"
  let s:mx_zen_kana = "[".han_kana."]\\+"
  let s:mx_han_eisu = '[０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ]\+'
  let s:mx_zen_eisu = '[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]\+'
  let s:mx_han_kigou = '[！”＃＄％＆’（）＊＋，－．／：；＜＝＞？＠［￥］＾＿‘｛｜｝～]\+'
  let s:mx_zen_kigou = "[!\"#$%&'()*+,\\-./:;<=>?@[\\\\\\]^_`{|}~]\\+"
  let s:targetlist = "han_all\<NL>zen_all\<NL>han_ascii\<NL>zen_ascii\<NL>han_kana\<NL>zen_kana\<NL>han_eisu\<NL>zen_eisu\<NL>han_kigou\<NL>zen_kigou"

  " 半角→全角テーブル作成
  let tmp = ''
  let tmp = tmp . " 　!！\"”#＃$＄%％&＆'’(（)）*＊+＋,，-－.．/／"
  let tmp = tmp . '0０1１2２3３4４5５6６7７8８9９:：;；<＜=＝>＞?？'
  let tmp = tmp . '@＠AＡBＢCＣDＤEＥFＦGＧHＨIＩJＪKＫLＬMＭNＮOＯ'
  let tmp = tmp . 'PＰQＱRＲSＳTＴUＵVＶWＷXＸYＹZＺ[［\￥]］^＾_＿'
  let tmp = tmp . '`‘aａbｂcｃdｄeｅfｆgｇhｈiｉjｊkｋlｌmｍnｎoｏ'
  let tmp = tmp . 'pｐqｑrｒsｓtｔuｕvｖwｗxｘyｙzｚ{｛|｜}｝~～'
  let tmp = tmp . '｡。｢「｣」､、ｦヲｧァｨィｩゥｪェｫォｬャｭュｮョｯッ'
  let tmp = tmp . 'ｰーｱアｲイｳウｴエｵオｶカｷキｸクｹケｺコｻサｼシｽスｾセｿソ'
  let tmp = tmp . 'ﾀタﾁチﾂツﾃテﾄトﾅナﾆニﾇヌﾈネﾉノﾊハﾋヒﾌフﾍヘﾎホﾏマ'
  let tmp = tmp . 'ﾐミﾑムﾒメﾓモﾔヤﾕユﾖヨﾗラﾘリﾙルﾚレﾛロﾜワﾝンﾞ゛ﾟ゜'
  let tmp = tmp . 'ｳﾞヴｶﾞガｷﾞギｸﾞグｹﾞゲｺﾞゴｻﾞザｼﾞジｽﾞズｾﾞゼｿﾞゾ'
  let tmp = tmp . 'ﾀﾞダﾁﾞヂﾂﾞヅﾃﾞデﾄﾞドﾊﾞバﾋﾞビﾌﾞブﾍﾞベﾎﾞボ'
  let tmp = tmp . 'ﾊﾟパﾋﾟピﾌﾟプﾍﾟペﾎﾟポ'
  let tmp = tmp . ''
  let s:table_h2z = tmp

  " 全角→半角変換テーブルを作成する。
  let s:table_z2h = ''
  let startcol = 0
  let endcol = strlen(s:table_h2z)
  let curcol = 0
  let mx = '^\(' . s:match_hankaku . '\)\(.\)'
  while curcol < endcol
    let char = matchstr(s:table_h2z, mx, curcol)
    let s:table_z2h = s:table_z2h . substitute(char, mx, '\2\1', '')
    let curcol = curcol + strlen(char)
  endwhile
endfunction

"
" コマンドで指定された領域を変換する
"
function! s:ToggleLineWise(operator) range
  call s:Initialize()

  let ncurline = a:firstline
  while ncurline <= a:lastline
    call setline(ncurline, s:ToggleLine(getline(ncurline), 0, 0, a:operator))
    let ncurline = ncurline + 1
  endwhile
endfunction

"
" 与えられた文字列を変換して返す。
"
function! s:ToggleLine(line, startcolumn, endcolumn, operator)
  let endcol = ((a:endcolumn > 0 && a:endcolumn < strlen(a:line))? a:endcolumn : strlen(a:line)) - 1
  let startcol = a:startcolumn > 0 ? a:startcolumn - 1: 0
  let curcol = startcol
  let newline = ''
  while curcol <= endcol
    let char = matchstr(a:line, s:match_character, curcol)
    let newline = newline . s:{a:operator}Char(char)
    let curcol = curcol + strlen(char)
  endwhile
  return strpart(a:line, 0, startcol) . newline . strpart(a:line, curcol)
endfunction

function! ToHankaku(str)
  call s:Initialize()
  return s:ToggleLine(a:str, 0, 0, 'Hankaku')
endfunction

function! ToZenkaku(str)
  call s:Initialize()
  return s:ToggleLine(a:str, 0, 0, 'Zenkaku')
endfunction

"
" 入力charを可能ならば半角/全角変換して返す。変換できない場合はそのまま。
"
function! s:ToggleChar(char)
  return (s:IsHankaku(a:char)) ? (s:ZenkakuChar(a:char)) : (s:HankakuChar(a:char))
endfunction

"
" 入力charを可能ならば全角に変換して返す。変換できない場合はそのまま。
"
function! s:ZenkakuChar(char)
  if s:IsHankaku(a:char)
    let pos = matchend(s:table_h2z, '\V\C' . escape(a:char, '\'))
    if pos >= 0
      return matchstr(s:table_h2z, '.', pos)
    endif
  endif
  return a:char
endfunction

"
" 入力charを可能ならば半角に変換して返す。変換できない場合はそのまま。
"
function! s:HankakuChar(char)
  if !s:IsHankaku(a:char)
    let pos = matchend(s:table_z2h, '\V\C' . escape(a:char, '\'))
    if pos >= 0
      return matchstr(s:table_z2h, s:match_hankaku, pos)
    endif
  endif
  return a:char
endfunction

"
" 与えられた文字が半角かどうかを判定する。
"
function! s:IsHankaku(char)
  return a:char =~ '^' . s:match_hankaku . '$'
endfunction
