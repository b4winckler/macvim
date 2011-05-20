" vim:set ts=8 sts=2 sw=2 tw=0: (この行に関しては:help modelineを参照)
"
" 日本語向けにエンコードを設定するサンプル - Vim7用
"
" Last Change: 15-May-2011.
" Maintainer:  MURAOKA Taro <koron.kaoriya@gmail.com>

" 各エンコードを示す文字列のデフォルト値。s:CheckIconvCapabilityを()呼ぶことで
" 実環境に合わせた値に修正される。
"
let s:enc_cp932 = 'cp932'
let s:enc_eucjp = 'euc-jp'
let s:enc_jisx = 'iso-2022-jp'
let s:enc_utf8 = 'utf-8'

" 利用しているiconvライブラリの性能を調べる。
"
" 比較的新しいJISX0213をサポートしているか検査する。euc-jisx0213が定義してい
" る範囲の文字をcp932からeuc-jisx0213へ変換できるかどうかで判断する。
"
function! s:CheckIconvCapability()
  if !has('iconv') | return | endif
  if iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
    let s:enc_eucjp = 'euc-jisx0213,euc-jp'
    let s:enc_jisx = 'iso-2022-jp-3'
  else
    let s:enc_eucjp = 'euc-jp'
    let s:enc_jisx = 'iso-2022-jp'
  endif
endfunction

" 'fileencodings'を決定する。
"
" 利用しているiconvライブラリの性能及び、現在利用している'encoding'の値に応じ
" て、日本語で利用するのに最適な'fileencodings'を設定する。
"
function! s:DetermineFileencodings()
  if !has('iconv') | return | endif
  let value = 'ucs-bom,ucs-2le,ucs-2'
  if &encoding ==? 'utf-8'
    " UTF-8環境向けにfileencodingsを設定する
    let value = s:enc_jisx. ','.s:enc_cp932. ','.s:enc_eucjp. ','.value
  elseif &encoding ==? 'cp932'
    " CP932環境向けにfileencodingsを設定する
    let value = value. ','.s:enc_jisx. ','.s:enc_utf8. ','.s:enc_eucjp
  elseif &encoding ==? 'euc-jp' || &encoding ==? 'euc-jisx0213'
    " EUC-JP環境向けにfileencodingsを設定する
    let value = value. ','.s:enc_jisx. ','.s:enc_utf8. ','.s:enc_cp932
  else
    " TODO: 必要ならばその他のエンコード向けの設定をココに追加する
  endif
  if has('guess_encode')
    let value = 'guess,'.value
  endif
  let &fileencodings = value
endfunction


" 本ファイルを読み込み(sourceした)時に、最適な設定を実行する。
"
if kaoriya#switch#enabled('utf-8')
  set encoding=utf-8
else
  set encoding=japan
endif
call s:CheckIconvCapability()
call s:DetermineFileencodings()
