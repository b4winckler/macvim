"=============================================================================
" FILE: vimproc.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Oct 2012.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

if exists('g:loaded_vimproc')
  finish
elseif v:version < 702
  echoerr 'vimproc does not work this version of Vim "' . v:version . '".'
  finish
endif

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

command! -nargs=+ -complete=shellcmd VimProcBang call s:bang(<q-args>)
command! -nargs=+ -complete=shellcmd VimProcRead call s:read(<q-args>)

" Command functions:
function! s:bang(cmdline) "{{{
  " Expand % and #.
  let cmdline = join(map(vimproc#parser#split_args_through(
        \ vimproc#util#iconv(a:cmdline,
        \   vimproc#util#termencoding(), &encoding)),
        \ 'substitute(expand(v:val), "\n", " ", "g")'))

  " Open pipe.
  let subproc = vimproc#pgroup_open(cmdline, 1)

  call subproc.stdin.close()

  while !subproc.stdout.eof || !subproc.stderr.eof
    if !subproc.stdout.eof
      let output = subproc.stdout.read(10000, 0)
      if output != ''
        let output = vimproc#util#iconv(output,
              \ vimproc#util#stdoutencoding(), &encoding)

        echon output
        sleep 1m
      endif
    endif

    if !subproc.stderr.eof
      let output = subproc.stderr.read(10000, 0)
      if output != ''
        let output = vimproc#util#iconv(output,
              \ vimproc#util#stderrencoding(), &encoding)
        echohl WarningMsg | echon output | echohl None

        sleep 1m
      endif
    endif
  endwhile

  call subproc.stdout.close()
  call subproc.stderr.close()

  let [cond, last_status] = subproc.waitpid()
endfunction"}}}
function! s:read(cmdline) "{{{
  " Expand % and #.
  let cmdline = join(map(vimproc#parser#split_args_through(
        \ vimproc#util#iconv(a:cmdline,
        \   vimproc#util#termencoding(), &encoding)),
        \ 'substitute(expand(v:val), "\n", " ", "g")'))

  " Expand args.
  call append('.', split(vimproc#util#iconv(vimproc#system(cmdline),
        \ vimproc#util#stdoutencoding(), &encoding), '\r\n\|\n'))
endfunction"}}}

let g:loaded_vimproc = 1

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" vim: foldmethod=marker
