
function s:parse_prop(lines)
  " items = [[start, end, prop], ...]
  let items = []

  " 1. parse lines
  for line in getline(1, '$')
    let line = substitute(line, '\s*#.*', '', '')
    if line == ""
      continue
    endif
    if line =~ '\.\.'
      "UUUU..UUUU;XX
      let m = matchlist(line, '\v^(\x+)\.\.(\x+);(\S+)$')
      call add(items, [str2nr(m[1], 16), str2nr(m[2], 16), m[3]])
    else
      "UUUU;XX
      let m = matchlist(line, '\v^(\x+);(\S+)$')
      call add(items, [str2nr(m[1], 16), str2nr(m[1], 16), m[2]])
    endif
  endfor

  " 2. reduce
  let i = 0
  while i < len(items) - 1
    if items[i][2] == items[i + 1][2] && items[i][1] + 1 == items[i + 1][0]
      let items[i][1] = items[i + 1][1]
      unlet items[i + 1]
    else
      let i += 1
    endif
  endwhile

  return items
endfunction

function s:prop_bsearch(ucs4, table)
  let [left, right] = [0, len(a:table)]
  while left < right
    let mid = (left + right) / 2
    let item = a:table[mid]
    if a:ucs4 < item[0]
      let right = mid
    elseif item[1] < a:ucs4
      let left = mid + 1
    else
      return item
    endif
  endwhile
  return []
endfunction

function! s:main()
  if !filereadable('LineBreak.txt')
    edit http://www.unicode.org/Public/UNIDATA/LineBreak.txt
    write LineBreak.txt
  else
    edit LineBreak.txt
  endif
  let linebreak = s:parse_prop(getline(1, '$'))

  enew

  " MEMO: line length is optimized for Vim's reading buffer size.
  $put ='let s:tmp = []'
  let n = 3
  for i in range(0, len(linebreak) - 1, n)
    let s = ''
    for [start, end, prop] in linebreak[i : i + n - 1]
      if s != ''
        let s .= ','
      endif
      let s .= printf('[0x%04X,0x%04X,''%s'']', start, end, prop)
    endfor
    $put =printf('call extend(s:tmp, [%s])', s)
  endfor
  $put ='let s:linebreak_table = s:tmp'
  $put ='unlet s:tmp'
  $put =''

  $put ='let s:tmp = []'
  for x in range(0x100)
    let row = []
    for y in range(0x100)
      let item = s:prop_bsearch(x * 0x100 + y, linebreak)
      if empty(item)
        let prop = 'XX'
      else
        let [start, end, prop] = item
      endif
      call add(row, prop)
    endfor
    if count(row, prop) == len(row)
      let row = [prop]
    endif
    let s = join(map(row, "'''' . v:val . ''''"), ',')
    $put =printf('call add(s:tmp, [%s])', s)
  endfor
  $put ='let s:linebreak_bmp = s:tmp'
  $put ='unlet s:tmp'
  $put =''

endfunction

call s:main()
