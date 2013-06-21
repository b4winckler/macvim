scriptencoding utf-8
" vim:set ts=8 sts=2 sw=2 tw=0 et:
"
" Switches by existance of files in $VIM/switches/enabled directory.
"
" (ほぼ)起動時の$VIM/switches/enabledディレクトリ下のファイルの有無を調べるス
" イッチ.
"
" Last Change:  16-Sep-2011.
" Maintainer:  MURAOKA Taro <koron.kaoriya@gmail.com>

let g:kaoriya_switch = {}
for path in split(glob($VIM.'/switches/enabled/*.vim'), '\n')
  let g:kaoriya_switch[fnamemodify(path, ':t:r')] = 1
endfor

function! kaoriya#switch#enabled(name)
  if exists('g:kaoriya_switch')
    if has_key(g:kaoriya_switch, a:name)
      return g:kaoriya_switch[a:name]
    endif
  endif
  return 0
endfunction
