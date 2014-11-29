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
" �R�}���h:
"   :[raneg]Hankaku
"   :[range]Zenkaku
"   :[range]ToggleHZ
"   :[range]HzjaConvert {target}
"
" �L�[�}�b�s���O:
"   �ȉ��̓r�W���A���I��̈�ɑ΂��鑀��ł��B�܂�()����HzjaConvert�R�}���h
"   �Ɗ֐��ɓn���Atarget�Ɏw��\�ȕ�����ł��B
"     gHL	�\�ȕ�����S�Ĕ��p�ɕϊ�����	(han_all)
"     gZL	�\�ȕ�����S�đS�p�ɕϊ�����	(zen_all)
"     gHA	ASCII������S�Ĕ��p�ɕϊ�����	(han_ascii)
"     gZA	ASCII������S�đS�p�ɕϊ�����	(zen_ascii)
"     gHM	�L����S�Ĕ��p�ɕϊ�����	(han_kigou)
"     gZM	�L����S�đS�p�ɕϊ�����	(zen_kigou)
"     gHW	�p������S�Ĕ��p�ɕϊ�����	(han_eisu)
"     gZW	�p������S�đS�p�ɕϊ�����	(zen_eisu)
"     gHJ	�J�^�J�i��S�Ĕ��p�ɕϊ�����	(han_kana)
"     gZJ	�J�^�J�i��S�đS�p�ɕϊ�����	(zen_kana)
"   �ȉ��͎g�p�p�x�̍������l�����āA��L�Əd�������@�\�Ƃ��Ċ��蓖�Ă�ꂽ
"   �L�[�}�b�v�ł��B
"     gHH	ASCII������S�Ĕ��p�ɕϊ�����	(han_ascii)
"     gZZ	�J�^�J�i��S�đS�p�ɕϊ�����	(zen_kana)
" 
" �֐�:
"   ToHankaku(str)	������𔼊p�֕ϊ�����
"   ToZenkaku(str)	�������S�p�֕ϊ�����
"   HzjaConvert(str, target)
"			�������target�ɏ]���ϊ�����Btarget�̈Ӗ��̓L�[�}�b
"			�s���O�̍��ڂ��Q�ƁB
"
" ���j���[�g��:
"   GUI���ł̓r�W���A���I�����̃|�b�v�A�b�v���j���[(�E�N���b�N���j���[)��
"   �ϊ��p�̃R�}���h���ǉ�����܂��B
"
" ���̃v���O�C����Ǎ��݂����Ȃ�����.vimrc�Ɏ��̂悤�ɏ�������:
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
  vnoremenu 1.130.100 PopUp.�S�p�����p(&H).�S��(&L) <C-\><C-N>:call <SID>HzjaConvertVisual('han_all')<CR>
  vnoremenu 1.130.110 PopUp.�S�p�����p(&H).ASCII(&A) <C-\><C-N>:call <SID>HzjaConvertVisual('han_ascii')<CR>
  vnoremenu 1.130.120 PopUp.�S�p�����p(&H).�L��(&M) <C-\><C-N>:call <SID>HzjaConvertVisual('han_kigou')<CR>
  vnoremenu 1.130.130 PopUp.�S�p�����p(&H).�p��(&W) <C-\><C-N>:call <SID>HzjaConvertVisual('han_eisu')<CR>
  vnoremenu 1.130.140 PopUp.�S�p�����p(&H).�J�^�J�i(&J) <C-\><C-N>:call <SID>HzjaConvertVisual('han_kana')<CR>
  vnoremenu 1.140.100 PopUp.���p���S�p(&Z).�S��(&L) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_all')<CR>
  vnoremenu 1.140.110 PopUp.���p���S�p(&Z).ASCII(&A) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_ascii')<CR>
  vnoremenu 1.140.120 PopUp.���p���S�p(&Z).�L��(&M) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kigou')<CR>
  vnoremenu 1.140.130 PopUp.���p���S�p(&Z).�p��(&W) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_eisu')<CR>
  vnoremenu 1.140.140 PopUp.���p���S�p(&Z).�J�^�J�i(&J) <C-\><C-N>:call <SID>HzjaConvertVisual('zen_kana')<CR>
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

" �^����ꂽ������̔��p�S�p�����𑊌݂ɕϊ�����B�ϊ��̕��@�͈���target�ŕ�
" ����Ƃ��Ďw�肷��B�w��ł��镶����͈ȉ��̂Ƃ���B
"
"   han_all	�S�Ă̑S�p���������p
"   han_ascii	�S�p�A�X�L�[�����p
"   han_kana	�S�p�J�^�J�i�����p
"   han_eisu	�S�p�p�������p
"   han_kigou	�S�p�L�������p
"   zen_all	�S�Ă̔��p�������S�p
"   zen_ascii	���p�A�X�L�[���S�p
"   zen_kana	���p�J�^�J�i���S�p
"   zen_eisu	���p�p�����S�p
"   zen_kigou	���p�L�����S�p
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

  let s:match_character = '\%([���������������������]�\|[�����]�\|.\)'
  let s:match_hankaku = '\%([���������������������]�\|[�����]�\|[ -~��������������������������������������������������������������]\)'

  let zen_ascii = '�@�I�h���������f�i�j���{�C�|�D�^�O�P�Q�R�S�T�U�V�W�X�F�G�������H���`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y�m���n�O�Q�e�����������������������������������������������������o�b�p�`'
  let zen_kana = '�B�u�v�A���@�B�D�F�H�������b�[�A�C�E�G�I�J�L�N�P�R�T�V�X�Z�\�^�`�c�e�g�i�j�k�l�m�n�q�t�w�z�}�~���������������������������J�K���K�M�O�Q�S�U�W�Y�[�]�_�a�d�f�h�o�r�u�x�{�p�s�v�y�|'
  let han_ascii = " !\"#$%&'()*+,\\-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
  let han_kana = '��������������������������������������������������������������'
  let s:mx_han_all = "[".zen_ascii.zen_kana."]\\+"
  let s:mx_zen_all = "[".han_ascii.han_kana."]\\+"
  let s:mx_han_ascii = "[".zen_ascii."]\\+"
  let s:mx_zen_ascii = "[".han_ascii."]\\+"
  let s:mx_han_kana = "[".zen_kana."]\\+"
  let s:mx_zen_kana = "[".han_kana."]\\+"
  let s:mx_han_eisu = '[�O�P�Q�R�S�T�U�V�W�X�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y����������������������������������������������������]\+'
  let s:mx_zen_eisu = '[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]\+'
  let s:mx_han_kigou = '[�I�h���������f�i�j���{�C�|�D�^�F�G�������H���m���n�O�Q�e�o�b�p�`]\+'
  let s:mx_zen_kigou = "[!\"#$%&'()*+,\\-./:;<=>?@[\\\\\\]^_`{|}~]\\+"
  let s:targetlist = "han_all\<NL>zen_all\<NL>han_ascii\<NL>zen_ascii\<NL>han_kana\<NL>zen_kana\<NL>han_eisu\<NL>zen_eisu\<NL>han_kigou\<NL>zen_kigou"

  " ���p���S�p�e�[�u���쐬
  let tmp = ''
  let tmp = tmp . " �@!�I\"�h#��$��%��&��'�f(�i)�j*��+�{,�C-�|.�D/�^"
  let tmp = tmp . '0�O1�P2�Q3�R4�S5�T6�U7�V8�W9�X:�F;�G<��=��>��?�H'
  let tmp = tmp . '@��A�`B�aC�bD�cE�dF�eG�fH�gI�hJ�iK�jL�kM�lN�mO�n'
  let tmp = tmp . 'P�oQ�pR�qS�rT�sU�tV�uW�vX�wY�xZ�y[�m\��]�n^�O_�Q'
  let tmp = tmp . '`�ea��b��c��d��e��f��g��h��i��j��k��l��m��n��o��'
  let tmp = tmp . 'p��q��r��s��t��u��v��w��x��y��z��{�o|�b}�p~�`'
  let tmp = tmp . '��B��u��v��A�����@��B��D��F��H�����������b'
  let tmp = tmp . '��[��A��C��E��G��I��J��L��N��P��R��T��V��X��Z��\'
  let tmp = tmp . '��^��`cÃeăgŃiƃjǃkȃlɃmʃn˃q̃t̓w΃zσ}'
  let tmp = tmp . 'Ѓ~у�҃�Ӄ�ԃ�Ճ�փ�׃�؃�ك�ڃ�ۃ�܃�݃�ށJ߁K'
  let tmp = tmp . '�ރ��ރK�ރM�ރO�ރQ�ރS�ރU�ރW�ރY�ރ[�ރ]'
  let tmp = tmp . '�ރ_�ރa�ރd�ރf�ރh�ރo�ރr�ރu�ރx�ރ{'
  let tmp = tmp . '�߃p�߃s�߃v�߃y�߃|'
  let tmp = tmp . ''
  let s:table_h2z = tmp

  " �S�p�����p�ϊ��e�[�u�����쐬����B
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
" �R�}���h�Ŏw�肳�ꂽ�̈��ϊ�����
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
" �^����ꂽ�������ϊ����ĕԂ��B
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
" ����char���\�Ȃ�Δ��p/�S�p�ϊ����ĕԂ��B�ϊ��ł��Ȃ��ꍇ�͂��̂܂܁B
"
function! s:ToggleChar(char)
  return (s:IsHankaku(a:char)) ? (s:ZenkakuChar(a:char)) : (s:HankakuChar(a:char))
endfunction

"
" ����char���\�Ȃ�ΑS�p�ɕϊ����ĕԂ��B�ϊ��ł��Ȃ��ꍇ�͂��̂܂܁B
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
" ����char���\�Ȃ�Δ��p�ɕϊ����ĕԂ��B�ϊ��ł��Ȃ��ꍇ�͂��̂܂܁B
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
" �^����ꂽ���������p���ǂ����𔻒肷��B
"
function! s:IsHankaku(char)
  return a:char =~ '^' . s:match_hankaku . '$'
endfunction
