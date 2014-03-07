"=============================================================================
" FILE: vimproc.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com> (Modified)
"          Yukihiro Nakadaira <yukihiro.nakadaira at gmail.com> (Original)
" Last Modified: 31 Dec 2013.
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


if exists('g:vimproc#disable')
  finish
endif

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:print_error(string)
  echohl Error | echomsg a:string | echohl None
endfunction

" Check 'encoding' "{{{
if &encoding =~# '^euc-jp'
  call s:print_error('Sorry, vimproc is not supported this encoding environment.')
  call s:print_error('You should set ''encoding'' option to "utf-8" '
        \ .'and set ''termencoding'' option to "euc-jp".')
  finish
endif
"}}}

" Global options definition. "{{{
" Set the default of g:vimproc_dll_path by judging OS "{{{
if vimproc#util#is_windows()
  if has('win64')
    let s:vimproc_dll_basename = 'vimproc_win64.dll'
  else
    let s:vimproc_dll_basename = 'vimproc_win32.dll'
  endif
elseif vimproc#util#is_cygwin()
  let s:vimproc_dll_basename = 'vimproc_cygwin.dll'
elseif vimproc#util#is_mac()
  let s:vimproc_dll_basename = 'vimproc_mac.so'
else
  let s:vimproc_dll_basename = 'vimproc_unix.so'
endif
"}}}

call vimproc#util#set_default(
      \ 'g:vimproc#dll_path',
      \ expand('<sfile>:p:h') . '/' . s:vimproc_dll_basename,
      \ 'g:vimproc_dll_path')
unlet s:vimproc_dll_basename

call vimproc#util#set_default(
      \ 'g:vimproc#password_pattern',
      \ '\%(Enter \|[Oo]ld \|[Nn]ew \|login '  .
      \'\|Kerberos \|CVS \|UNIX \| SMB \|LDAP \|\[sudo] ' .
      \'\|^\|\n\|''s \)\%([Pp]assword\|[Pp]assphrase\)\>',
      \ 'g:vimproc_password_pattern')
call vimproc#util#set_default(
      \ 'g:vimproc#popen2_commands', {
      \     'sh' : 1, 'bash' : 1, 'zsh' : 1, 'csh' : 1, 'tcsh' : 1,
      \     'tmux' : 1, 'screen' : 1, 'su' : 1,
      \     'python' : 1, 'rhino' : 1, 'ipython' : 1, 'ipython3' : 1, 'yaourt' : 1,
      \ }, 'g:vimproc_popen2_commands')
call vimproc#util#set_default(
      \ 'g:stdinencoding', 'char')
call vimproc#util#set_default(
      \ 'g:stdoutencoding', 'char')
call vimproc#util#set_default(
      \ 'g:stderrencoding', 'char')
"}}}

" Constants {{{
function! s:define_signals()
  let s:signames = []
  let xs = s:libcall('vp_get_signals', [])
  for x in xs
    let [name, val] = split(x, ':')
    let g:vimproc#{name} = str2nr(val)
    call add(s:signames, name)
  endfor
endfunction
" }}}

let g:vimproc#dll_path =
      \ vimproc#util#iconv(
      \ vimproc#util#substitute_path_separator(g:vimproc#dll_path),
      \ &encoding, vimproc#util#termencoding())

" Backward compatibility.
let g:vimproc_password_pattern = g:vimproc#password_pattern

if !filereadable(g:vimproc#dll_path) "{{{
  function! vimproc#get_last_status()
    return v:shell_error
  endfunction

  function! vimproc#get_last_errmsg()
    return ''
  endfunction

  function! vimproc#system(...)
    return call('system', a:000)
  endfunction

  echoerr printf('vimproc''s DLL: "%s" is not found.
        \ Please read :help vimproc and make it.', g:vimproc#dll_path)

  finish
endif"}}}

function! vimproc#version() "{{{
  return str2nr(printf('%2d%02d', 7, 1))
endfunction"}}}
function! vimproc#dll_version() "{{{
  let [dll_version] = s:libcall('vp_dlversion', [])
  return str2nr(dll_version)
endfunction"}}}

"-----------------------------------------------------------
" API

function! vimproc#open(filename) "{{{
  let filename = vimproc#util#iconv(fnamemodify(a:filename, ':p'),
        \ &encoding, vimproc#util#termencoding())

  if filename =~ '^\%(https\?\|ftp\)://'
          \ && !vimproc#host_exists(filename)
    " URI is invalid.
    call s:print_error('vimproc#open: URI "' . filename . '" is invalid.')
    return
  endif

  " Detect desktop environment.
  if vimproc#util#is_windows()
    " For URI only.
    "execute '!start rundll32 url.dll,FileProtocolHandler' filename

    call s:libcall('vp_open', [filename])
  elseif has('win32unix')
    " Cygwin.
    call vimproc#system(['cygstart', filename])
  elseif executable('xdg-open')
    " Linux.
    call vimproc#system_bg(['xdg-open', filename])
  elseif exists('$KDE_FULL_SESSION') && $KDE_FULL_SESSION ==# 'true'
    " KDE.
    call vimproc#system_bg(['kioclient', 'exec', filename])
  elseif exists('$GNOME_DESKTOP_SESSION_ID')
    " GNOME.
    call vimproc#system_bg(['gnome-open', filename])
  elseif executable('exo-open')
    " Xfce.
    call vimproc#system_bg(['exo-open', filename])
  elseif vimproc#util#is_mac() && executable('open')
    " Mac OS.
    call vimproc#system_bg(['open', filename])
  else
    " Give up.
    call s:print_error('vimproc#open: Not supported.')
  endif
endfunction"}}}

function! vimproc#get_command_name(command, ...) "{{{
  let path = get(a:000, 0, $PATH)

  let cnt = a:0 < 2 ? 1 : a:2

  let files = split(substitute(vimproc#util#substitute_path_separator(
        \ vimproc#filepath#which(a:command, path)), '//', '/', 'g'), '\n')

  if cnt < 0
    return files
  endif

  let file = get(files, cnt-1, '')

  if file == ''
    throw printf(
          \ 'vimproc#get_command_name: File "%s" is not found.', a:command)
  endif

  return file
endfunction"}}}

function! s:system(cmdline, is_passwd, input, timeout, is_pty) "{{{
  if empty(a:cmdline)
    let s:last_status = 0
    let s:last_errmsg = ''
    return ''
  endif

  " Open pipe.
  let subproc = (type(a:cmdline[0]) == type('')) ? vimproc#popen3(a:cmdline) :
        \ a:is_pty ? vimproc#ptyopen(a:cmdline):
        \ vimproc#pgroup_open(a:cmdline)

  if a:input != ''
    " Write input.
    call subproc.stdin.write(a:input)
  endif

  if a:timeout > 0 && has('reltime') && v:version >= 702
    let start = reltime()
    let timeout = a:timeout
  else
    let timeout = 0
  endif

  if !a:is_passwd
    call subproc.stdin.close()
  endif

  let output = ''
  let s:last_errmsg = ''
  while !subproc.stdout.eof || !subproc.stderr.eof
    if timeout > 0 "{{{
      " Check timeout.
      let end = split(reltimestr(reltime(start)))[0] * 1000
      if end > timeout && !subproc.stdout.eof
        " Kill process.
        try
          call subproc.kill(g:vimproc#SIGTERM)
          call subproc.waitpid()
        catch
          " Ignore error.
        endtry

        throw 'vimproc: vimproc#system(): Timeout.'
      endif
    endif"}}}

    if !subproc.stdout.eof "{{{
      let out = subproc.stdout.read(1000, 0)

      if a:is_passwd && out =~# g:vimproc_password_pattern
        redraw
        echo out

        " Password input.
        set imsearch=0
        let in = vimproc#util#iconv(inputsecret('Input Secret : ')."\<NL>",
              \ &encoding, vimproc#util#termencoding())

        call subproc.stdin.write(in)
      else
        let output .= out
      endif
    endif"}}}

    if !subproc.stderr.eof "{{{
      let out = subproc.stderr.read(1000, 0)

      if a:is_passwd && out =~# g:vimproc_password_pattern
        redraw
        echo out

        " Password input.
        set imsearch=0
        let in = vimproc#util#iconv(inputsecret('Input Secret : ') . "\<NL>",
              \ &encoding, vimproc#util#termencoding())

        call subproc.stdin.write(in)
      else
        let s:last_errmsg .= out
        let output .= out
      endif
    endif"}}}
  endwhile

  let [cond, status] = subproc.waitpid()

  " Newline convert.
  if vimproc#util#is_mac()
    let output = substitute(output, '\r\n\@!', '\n', 'g')
  elseif has('win32') || has('win64')
    let output = substitute(output, '\r\n', '\n', 'g')
  endif

  return output
endfunction"}}}
function! vimproc#system(cmdline, ...) "{{{
  if type(a:cmdline) == type('')
    if a:cmdline =~ '&\s*$'
      let cmdline = substitute(a:cmdline, '&\s*$', '', '')
      return vimproc#system_bg(cmdline)
    endif

    let args = vimproc#parser#parse_statements(a:cmdline)
    for arg in args
      let arg.statement = vimproc#parser#parse_pipe(arg.statement)
    endfor
  else
    let args = [{'statement' :
          \ [{ 'fd' : { 'stdin' : '', 'stdout' : '', 'stderr' : '' },
          \   'args' : a:cmdline }], 'condition' : 'always' }]
  endif

  let timeout = get(a:000, 1, 0)
  let input = get(a:000, 0, '')

  return s:system(args, 0, input, timeout, 0)
endfunction"}}}
function! vimproc#system2(...) "{{{
  if empty(a:000)
    return ''
  endif

  if len(a:0) > 1
    let args = deepcopy(a:000)
    let args[1] = vimproc#util#iconv(
          \ args[1], &encoding, vimproc#util#stdinencoding())
  else
    let args = a:000
  endif
  let output = call('vimproc#system', args)

  " This function converts application encoding to &encoding.
  let output = vimproc#util#iconv(
        \ output, vimproc#util#stdoutencoding(), &encoding)
  let s:last_errmsg = vimproc#util#iconv(
        \ s:last_errmsg, vimproc#util#stderrencoding(), &encoding)

  return output
endfunction"}}}
function! vimproc#system_passwd(cmdline, ...) "{{{
  if type(a:cmdline) == type('')
    let args = vimproc#parser#parse_pipe(a:cmdline)
  else
    let args = [{ 'fd' : { 'stdin' : '', 'stdout' : '', 'stderr' : '' },
          \ 'args' : a:cmdline }]
  endif

  let timeout = a:0 >= 2 ? a:2 : 0
  let input = a:0 >= 1 ? a:1 : ''

  let lang_save = $LANG
  try
    let $LANG = 'C'

    return s:system(args, 1, input, timeout, 1)
  finally
    let $LANG = lang_save
  endtry
endfunction"}}}
function! vimproc#system_bg(cmdline) "{{{
  " Open pipe.
  if type(a:cmdline) == type('')
    if a:cmdline =~ '&\s*$'
      let cmdline = substitute(a:cmdline, '&\s*$', '', '')
      return vimproc#system_bg(cmdline)
    endif

    let args = vimproc#parser#parse_statements(a:cmdline)
    for arg in args
      let arg.statement = vimproc#parser#parse_pipe(arg.statement)
    endfor
  else
    let args = [{'statement' :
          \ [{ 'fd' : { 'stdin' : '', 'stdout' : '', 'stderr' : '' },
          \   'args' : a:cmdline }], 'condition' : 'always' }]
  endif

  let subproc = vimproc#pgroup_open(args)
  if empty(subproc)
    " Not supported path error.
    return ''
  endif

  " Close handles.
  call s:close_all(subproc)

  let s:bg_processes[subproc.pid] = subproc.pid

  return ''
endfunction"}}}
function! vimproc#system_gui(cmdline) "{{{
  if vimproc#util#is_windows()
    silent execute ':!start ' . join(map(vimproc#parser#split_args(a:cmdline), '"\"".v:val."\""'))
    return ''
  else
    return vimproc#system_bg(a:cmdline)
  endif
endfunction"}}}

function! vimproc#get_last_status() "{{{
  return s:last_status
endfunction"}}}
function! vimproc#get_last_errmsg() "{{{
  return substitute(vimproc#util#iconv(s:last_errmsg,
        \ vimproc#util#stderrencoding(), &encoding), '\n$', '', '')
endfunction"}}}

function! vimproc#shellescape(string) "{{{
  return string(a:string)
endfunction"}}}

function! vimproc#fopen(path, flags, ...) "{{{
  let mode = get(a:000, 0, 0644)
  let fd = s:vp_file_open(a:path, a:flags, mode)
  let proc = s:fdopen(fd, 'vp_file_close', 'vp_file_read', 'vp_file_write')
  return proc
endfunction"}}}

function! vimproc#popen2(args) "{{{
  let args = type(a:args) == type('') ?
        \ vimproc#parser#split_args(a:args) :
        \ a:args

  return s:plineopen(2, [{
        \ 'args' : args,
        \ 'fd' : { 'stdin' : '', 'stdout' : '', 'stderr' : '' },
        \ }], 0)
endfunction"}}}
function! vimproc#popen3(args) "{{{
  let args = type(a:args) == type('') ?
        \ vimproc#parser#split_args(a:args) :
        \ a:args

  return s:plineopen(3, [{
        \ 'args' : args,
        \ 'fd' : { 'stdin' : '', 'stdout' : '', 'stderr' : '' },
        \ }], 0)
endfunction"}}}

function! vimproc#plineopen2(commands, ...) "{{{
  let commands = type(a:commands) == type('') ?
        \ vimproc#parser#parse_pipe(a:commands) :
        \ a:commands
  let is_pty = get(a:000, 0, 0)

  return s:plineopen(2, commands, is_pty)
endfunction"}}}
function! vimproc#plineopen3(commands, ...) "{{{
  let commands = type(a:commands) == type('') ?
        \ vimproc#parser#parse_pipe(a:commands) :
        \ a:commands
  let is_pty = get(a:000, 0, 0)

  return s:plineopen(3, commands, is_pty)
endfunction"}}}
function! s:plineopen(npipe, commands, is_pty) "{{{
  let pid_list = []
  let stdin_list = []
  let stdout_list = []
  let stderr_list = []
  let npipe = a:npipe

  " Open input.
  let hstdin = (empty(a:commands) || a:commands[0].fd.stdin == '')?
        \ 0 : vimproc#fopen(a:commands[0].fd.stdin, 'O_RDONLY').fd

  let is_pty = !vimproc#util#is_windows() && a:is_pty

  let cnt = 0
  for command in a:commands
    if is_pty && command.fd.stdout == '' && cnt == 0
          \ && len(a:commands) != 1
      " pty_open() use pipe.
      let hstdout = 1
    else
      let mode = 'O_WRONLY | O_CREAT'
      if command.fd.stdout =~ '^>'
        let mode .= ' | O_APPEND'
        let command.fd.stdout = command.fd.stdout[1:]
      else
        let mode .= ' | O_TRUNC'
      endif

      let hstdout = s:is_pseudo_device(command.fd.stdout) ?
            \ 0 : vimproc#fopen(command.fd.stdout, mode).fd
    endif

    if is_pty && command.fd.stderr == '' && cnt == 0
          \ && len(a:commands) != 1
      " pty_open() use pipe.
      let hstderr = 1
    else
      let mode = 'O_WRONLY | O_CREAT'
      if command.fd.stderr =~ '^>'
        let mode .= ' | O_APPEND'
        let command.fd.stderr = command.fd.stderr[1:]
      else
        let mode .= ' | O_TRUNC'
      endif
      let hstderr = s:is_pseudo_device(command.fd.stderr) ?
            \ 0 : vimproc#fopen(command.fd.stderr, mode).fd
    endif

    if command.fd.stderr ==# '/dev/stdout'
      let npipe = 2
    endif

    let args = s:convert_args(command.args)
    let command_name = fnamemodify(args[0], ':t:r')
    let pty_npipe = cnt == 0
          \ && hstdin == 0 && hstdout == 0 && hstderr == 0
          \ && exists('g:vimproc#popen2_commands')
          \ && get(g:vimproc#popen2_commands, command_name, 0) != 0 ?
          \ 2 : npipe

    if is_pty && (cnt == 0 || cnt == len(a:commands)-1)
      " Use pty_open().
      let pipe = s:vp_pty_open(pty_npipe, winwidth(0)-5, winheight(0),
            \ hstdin, hstdout, hstderr, args)
    else
      let pipe = s:vp_pipe_open(pty_npipe,
            \ hstdin, hstdout, hstderr, args)
    endif

    if len(pipe) == 4
      let [pid, fd_stdin, fd_stdout, fd_stderr] = pipe
      let stderr = s:fdopen(fd_stderr,
            \ 'vp_pipe_close', 'vp_pipe_read', 'vp_pipe_write')
    else
      let [pid, fd_stdin, fd_stdout] = pipe
      let stderr = s:closed_fdopen(
            \ 'vp_pipe_close', 'vp_pipe_read', 'vp_pipe_write')
    endif

    call add(pid_list, pid)
    let stdin = s:fdopen(fd_stdin,
          \ 'vp_pipe_close', 'vp_pipe_read', 'vp_pipe_write')
    let stdin.is_pty = is_pty
          \ && (cnt == 0 || cnt == len(a:commands)-1)
          \ && hstdin == 0
    call add(stdin_list, stdin)
    let stdout = s:fdopen(fd_stdout,
          \ 'vp_pipe_close', 'vp_pipe_read', 'vp_pipe_write')
    let stdout.is_pty = is_pty
          \ && (cnt == 0 || cnt == len(a:commands)-1)
          \ && hstdout == 0
    call add(stdout_list, stdout)
    let stderr.is_pty = is_pty
          \ && (cnt == 0 || cnt == len(a:commands)-1)
          \ && hstderr == 0
    call add(stderr_list, stderr)

    let hstdin = stdout_list[-1].fd
    let cnt += 1
  endfor

  let proc = {}
  let proc.pid_list = pid_list
  let proc.pid = pid_list[-1]
  let proc.stdin = s:fdopen_pipes(stdin_list,
        \ 'vp_pipes_close', 'read_pipes', 'write_pipes')
  let proc.stdout = s:fdopen_pipes(stdout_list,
        \ 'vp_pipes_close', 'read_pipes', 'write_pipes')
  let proc.stderr = s:fdopen_pipes(stderr_list,
        \ 'vp_pipes_close', 'read_pipes', 'write_pipes')
  let proc.get_winsize = s:funcref('vp_get_winsize')
  let proc.set_winsize = s:funcref('vp_set_winsize')
  let proc.kill = s:funcref('vp_kill')
  let proc.waitpid = s:funcref('vp_waitpid')
  let proc.checkpid = s:funcref('vp_checkpid')
  let proc.is_valid = 1
  let proc.is_pty = is_pty
  if a:is_pty
    let proc.ttyname = ''
    let proc.get_winsize = s:funcref('vp_get_winsize')
    let proc.set_winsize = s:funcref('vp_set_winsize')
  endif

  return proc
endfunction"}}}

function! s:is_pseudo_device(filename) "{{{
  if vimproc#util#is_windows() && (
    \    a:filename ==# '/dev/stdin'
    \ || a:filename ==# '/dev/stdout'
    \ || a:filename ==# '/dev/stderr')
    return 1
  endif

  return a:filename == ''
        \ || a:filename ==# '/dev/null'
        \ || a:filename ==# '/dev/clip'
        \ || a:filename ==# '/dev/quickfix'
endfunction"}}}

function! vimproc#pgroup_open(statements, ...) "{{{
  if type(a:statements) == type('')
    let statements =
          \ vimproc#parser#parse_statements(a:statements)
    for statement in statements
      let statement.statement =
            \ vimproc#parser#parse_pipe(statement.statement)
    endfor
  else
    let statements = a:statements
  endif

  let is_pty = get(a:000, 0, 0)
  let npipe = get(a:000, 1, 3)

  return s:pgroup_open(statements, is_pty && !vimproc#util#is_windows(), npipe)
endfunction"}}}

function! s:pgroup_open(statements, is_pty, npipe) "{{{
  let proc = {}
  let proc.current_proc =
        \ vimproc#plineopen{a:npipe}(a:statements[0].statement, a:is_pty)

  let proc.pid = proc.current_proc.pid
  let proc.pid_list = proc.current_proc.pid_list
  let proc.condition = a:statements[0].condition
  let proc.statements = a:statements[1:]
  let proc.stdin = s:fdopen_pgroup(proc, proc.current_proc.stdin,
        \ 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
  let proc.stdout = s:fdopen_pgroup(proc, proc.current_proc.stdout,
        \ 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
  let proc.stderr = s:fdopen_pgroup(proc, proc.current_proc.stderr,
        \ 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
  let proc.kill = s:funcref('vp_pgroup_kill')
  let proc.waitpid = s:funcref('vp_pgroup_waitpid')
  let proc.is_valid = 1
  let proc.is_pty = 0
  " echomsg expand('<sfile>')
  " echomsg 'open:' string(map(copy(proc.current_proc.stdin.fd), 'v:val.fd'))
  " echomsg 'open:' string(map(copy(proc.current_proc.stdout.fd), 'v:val.fd'))
  " echomsg 'open:' string(map(copy(proc.current_proc.stderr.fd), 'v:val.fd'))

  return proc
endfunction"}}}

function! vimproc#ptyopen(commands, ...) "{{{
  let commands = type(a:commands) == type('') ?
        \ vimproc#parser#parse_pipe(a:commands) :
        \ a:commands
  let npipe = get(a:000, 0, 3)

  return s:plineopen(npipe, commands, !vimproc#util#is_windows())
endfunction"}}}

function! vimproc#socket_open(host, port) "{{{
  let fd = s:vp_socket_open(a:host, a:port)
  return s:fdopen(fd, 'vp_socket_close', 'vp_socket_read', 'vp_socket_write')
endfunction"}}}

function! vimproc#host_exists(host) "{{{
  let rval = s:vp_host_exists(
        \ substitute(substitute(a:host, '^\a\+://', '', ''), '/.*$', '', ''))
  return 0 + rval
endfunction"}}}

function! vimproc#kill(pid, sig) "{{{
  if a:sig == 0 && vimproc#util#is_windows()
    " Use waitpid().
    let [cond, status] = s:waitpid(a:pid)
    return cond ==# 'run'
  endif

  try
    let [ret] = s:libcall('vp_kill', [a:pid, a:sig])
  catch
    let s:last_errmsg = v:exception
    return 1
  endtry

  return ret
endfunction"}}}

function! vimproc#decode_signal(signal) "{{{
  for signame in s:signames
    if a:signal == g:vimproc#{signame}
      return signame
    endif
  endfor
  return 'UNKNOWN'
endfunction"}}}

function! vimproc#write(filename, string, ...) "{{{
  if a:string == ''
    return
  endif

  let mode = get(a:000, 0,
        \ a:filename =~ '^>' ? 'a' : 'w')

  let filename = a:filename =~ '^>' ?
        \ a:filename[1:] : a:filename

  if filename ==# '/dev/null'
    " Nothing.
  elseif filename ==# '/dev/clip'
    " Write to clipboard.

    if mode =~ 'a'
      let @+ .= a:string
    else
      let @+ = a:string
    endif
  elseif filename ==# '/dev/quickfix'
    " Write to quickfix.
    let qflist = getqflist()

    for str in split(a:string, '\n\|\r\n')
      if str =~ '^.\+:.\+:.\+$'
        let line = split(str[2:], ':')
        let filename = str[:1] . line[0]

        if len(line) >= 3 && line[1] =~ '^\d\+$'
          call add(qflist, {
                \ 'filename' : filename,
                \ 'lnum' : line[1],
                \ 'text' : join(line[2:], ':'),
                \ })
        else
          call add(qflist, {
                \ 'text' : str,
                \ })
        endif
      endif
    endfor

    call setqflist(qflist)
  else
    " Write file.

    let cmode = 'O_WRONLY | O_CREAT'
    if mode =~# 'a'
      " Append mode.
      let cmode .= '| O_APPEND'
    endif

    let hfile = vimproc#fopen(filename, cmode)
    call hfile.write(a:string)
    call hfile.close()
  endif
endfunction"}}}

function! vimproc#readdir(dirname) "{{{
  let dirname = vimproc#util#expand(a:dirname)
  if dirname == ''
    let dirname = getcwd()
  endif
  let dirname = substitute(dirname, '.\zs/$', '', '')

  if !vimproc#util#is_windows()
    let dirname = substitute(dirname, '//', '/', 'g')
  endif

  if !isdirectory(dirname)
    return []
  endif

  let dirname = vimproc#util#iconv(dirname, &encoding,
        \ vimproc#util#termencoding())

  try
    let files = s:libcall('vp_readdir', [dirname])
  catch /vp_readdir/
    return []
  endtry

  call map(filter(files, 'v:val !~ "/\\.\\.\\?$"'), 'vimproc#util#iconv(
        \ v:val, vimproc#util#termencoding(), &encoding)')
  if vimproc#util#is_windows()
    call map(files, 'vimproc#util#substitute_path_separator(v:val)')
  endif
  call map(files, "substitute(v:val, '/\\./', '/', 'g')")

  return files
endfunction"}}}

function! vimproc#delete_trash(filename) "{{{
  if !vimproc#util#is_windows()
    call s:print_error('Not implemented in this platform.')
    return
  endif

  let filename = a:filename

  if !filewritable(filename) && !isdirectory(filename)
    return 1
  endif

  " Substitute path separator to "/".
  let filename = substitute(
        \ fnamemodify(filename, ':p'), '/', '\\', 'g')

  " Delete last /.
  if filename =~ '[^:][/\\]$'
    " Delete last /.
    let filename = filename[: -2]
  endif

  " Encoding conversion.
  let filename = vimproc#util#iconv(filename,
        \ &encoding, vimproc#util#termencoding())

  let [ret] = s:libcall('vp_delete_trash', [filename])

  return str2nr(ret)
endfunction"}}}

function! vimproc#test_readdir(dirname) "{{{
  let start = reltime()
  call split(glob(a:dirname.'/*'), '\n')
  echomsg reltimestr(reltime(start))

  let start = reltime()
  call vimproc#readdir(a:dirname)
  echomsg reltimestr(reltime(start))
endfunction"}}}

function! s:close_all(self) "{{{
  if has_key(a:self, 'stdin')
    call a:self.stdin.close()
  endif
  if has_key(a:self, 'stdout')
    call a:self.stdout.close()
  endif
  if has_key(a:self, 'stderr')
    call a:self.stderr.close()
  endif
endfunction"}}}
function! s:close() dict "{{{
  if self.is_valid
    call self.f_close()
  endif

  let self.is_valid = 0
  let self.eof = 1
  let self.__eof = 1
endfunction"}}}
function! s:read(...) dict "{{{
  if self.__eof
    let self.eof = 1
    return ''
  endif

  let number = get(a:000, 0, -1)
  let timeout = get(a:000, 1, s:read_timeout)
  let [hd, eof] = self.f_read(number, timeout)
  let self.eof = eof
  let self.__eof = eof

  if hd == ''
    return ''
  endif

  " Note: if output string is too long, if_lua is too slow.
  return (vimproc#util#has_lua() && len(hd) < 1024) ?
        \ s:hd2str_lua([hd]) : s:hd2str([hd])
  " return s:hd2str([hd])
endfunction"}}}
function! s:read_lines(...) dict "{{{
  let res = self.buffer

  while !self.eof && stridx(res, "\n") < 0
    let out = call(self.read, a:000, self)
    if out  == ''
      break
    endif

    let res .= out
  endwhile

  let self.buffer = ''
  let lines = split(res, '\r*\n', 1)
  if !self.__eof
    let self.buffer = get(lines, -1, '')
    let lines = lines[ : -2]
  endif

  return lines
endfunction"}}}
function! s:read_line(...) dict "{{{
  let lines = call(self.read_lines, a:000, self)
  let self.buffer = join(lines[1:], "\n") . self.buffer
  let self.eof = (self.buffer != '') ?
        \ (self.__eof && self.buffer == '') : self.__eof
  return get(lines, 0, '')
endfunction"}}}

function! s:write(str, ...) dict "{{{
  let timeout = get(a:000, 0, s:write_timeout)
  let hd = s:str2hd(a:str)
  return self.f_write(hd, timeout)
endfunction"}}}

function! s:fdopen(fd, f_close, f_read, f_write) "{{{
  return {
        \ 'fd' : a:fd,
        \ 'eof' : 0, '__eof' : 0, 'is_valid' : 1, 'buffer' : '',
        \ 'f_close' : s:funcref(a:f_close), 'f_read' : s:funcref(a:f_read), 'f_write' : s:funcref(a:f_write),
        \ 'close' : s:funcref('close'), 'read' : s:funcref('read'), 'write' : s:funcref('write'),
        \ 'read_line' : s:funcref('read_line'), 'read_lines' : s:funcref('read_lines'),
        \}
endfunction"}}}
function! s:closed_fdopen(f_close, f_read, f_write) "{{{
  return {
        \ 'fd' : -1,
        \ 'eof' : 1, '__eof' : 1, 'is_valid' : 0, 'buffer' : '',
        \ 'f_close' : s:funcref(a:f_close), 'f_read' : s:funcref(a:f_read), 'f_write' : s:funcref(a:f_write),
        \ 'close' : s:funcref('close'), 'read' : s:funcref('read'), 'write' : s:funcref('write'),
        \ 'read_line' : s:funcref('read_line'), 'read_lines' : s:funcref('read_lines'),
        \}
endfunction"}}}
function! s:fdopen_pty(fd_stdin, fd_stdout, f_close, f_read, f_write) "{{{
  return {
        \ 'eof' : 0, '__eof' : 0, 'is_valid' : 1, 'buffer' : '',
        \ 'fd_stdin' : a:fd_stdin, 'fd_stdout' : a:fd_stdout,
        \ 'f_close' : s:funcref(a:f_close), 'f_read' : s:funcref(a:f_read), 'f_write' : s:funcref(a:f_write), 
        \ 'close' : s:funcref('close'), 'read' : s:funcref('read'), 'write' : s:funcref('write'),
        \ 'read_line' : s:funcref('read_line'), 'read_lines' : s:funcref('read_lines'),
        \}
endfunction"}}}
function! s:fdopen_pipes(fd, f_close, f_read, f_write) "{{{
  return {
        \ 'eof' : 0, '__eof' : 0, 'is_valid' : 1, 'buffer' : '',
        \ 'fd' : a:fd,
        \ 'f_close' : s:funcref(a:f_close),
        \ 'close' : s:funcref('close'), 'read' : s:funcref(a:f_read), 'write' : s:funcref(a:f_write),
        \ 'read_line' : s:funcref('read_line'), 'read_lines' : s:funcref('read_lines'),
        \}
endfunction"}}}
function! s:fdopen_pgroup(proc, fd, f_close, f_read, f_write) "{{{
  return {
        \ 'eof' : 0, '__eof' : 0, 'is_valid' : 1, 'buffer' : '',
        \ 'proc' : a:proc, 'fd' : a:fd,
        \ 'f_close' : s:funcref(a:f_close),
        \ 'close' : s:funcref('close'), 'read' : s:funcref(a:f_read), 'write' : s:funcref(a:f_write),
        \ 'read_line' : s:funcref('read_line'), 'read_lines' : s:funcref('read_lines'),
        \}
endfunction"}}}

function! s:garbage_collect(is_force) "{{{
  for pid in values(s:bg_processes)
    " Check processes.
    try
      let [cond, status] = s:libcall('vp_waitpid', [pid])
      " echomsg string([pid, cond, status])
      if cond !=# 'run' || a:is_force
        if cond !=# 'exit'
          " Kill process.
          call vimproc#kill(pid, g:vimproc#SIGTERM)
        endif

        if vimproc#util#is_windows()
          call s:libcall('vp_close_handle', [pid])
        endif
        call remove(s:bg_processes, pid)
      endif
    catch
      " Ignore error.
    endtry
  endfor
endfunction"}}}

" For debug API.
function! vimproc#_get_bg_processes() "{{{
  return s:bg_processes
endfunction"}}}

"-----------------------------------------------------------
" UTILS

function! s:str2hd(str)
  return join(map(range(len(a:str)),
        \ 'printf("%02X", char2nr(a:str[v:val]))'), '')
endfunction

function! s:hd2str(hd)
  " a:hd is a list because to avoid copying the value.
  return get(s:libcall('vp_decode', [a:hd[0]]), 0, '')
endfunction

function! s:hd2str_lua(hd)
  let ret = []
  lua << EOF
do
  local ret = vim.eval('ret')
  local hd = vim.eval('a:hd')
  if hd[0] == nil then
    hd[0] = ''
  end
  local len = string.len(hd[0])
  local s = ''
  for i = 1, len, 2 do
    s = s .. string.char(tonumber(string.sub(hd[0], i, i+1), 16))
  end

  ret:add(s)
end
EOF
  return ret[0]
endfunction

function! s:str2list(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:list2str(lis)
  return s:hd2str(s:list2hd([a:lis]))
endfunction

function! s:hd2list(hd)
  return map(split(a:hd, '..\zs'), 'str2nr(v:val, 16)')
endfunction

function! s:list2hd(lis)
  return join(map(a:lis, 'printf("%02X", v:val)'), '')
endfunction

function! s:convert_args(args) "{{{
  if empty(a:args)
    return []
  endif

  if vimproc#util#is_windows() && !executable(a:args[0])
    " Search from internal commands.
    let internal_commands = [
          \ 'copy', 'dir', 'echo', 'erase', 'ftype',
          \ 'md', 'mkdir', 'move', 'path', 'rd', 'ren', 'rename',
          \ 'rmdir', 'start', 'time', 'type', 'ver', 'vol']
    let index = index(internal_commands, a:args[0])
    if index >= 0
      " Use cmd.exe
      return ['cmd', '/c', internal_commands[index]] + a:args[1:]
    endif
  endif

  let command_name = vimproc#get_command_name(a:args[0])

  return vimproc#analyze_shebang(command_name) + a:args[1:]
endfunction"}}}

function! vimproc#analyze_shebang(filename) "{{{
  if !filereadable(a:filename) ||
        \ getfsize(a:filename) > 100000 ||
        \ (vimproc#util#is_windows() &&
        \ '.'.fnamemodify(a:filename, ':e') !~?
        \   '^'.substitute($PATHEXT, ';', '$\\|^', 'g').'$')
      " Maybe a binary file.
    return [a:filename]
  endif

  let lines = readfile(a:filename, '', 1)
  if empty(lines) || lines[0] !~ '^#!.\+'
    " Shebang not found.
    return [a:filename]
  endif

  " Get shebang line.
  let shebang = split(matchstr(lines[0], '^#!\zs.\+'))

  " Convert command name.
  if vimproc#util#is_windows()
        \ && shebang[0] =~ '^/'
    let shebang[0] = vimproc#get_command_name(
          \ fnamemodify(shebang[0], ':t'))
  endif

  return shebang + [a:filename]
endfunction"}}}

"-----------------------------------------------------------
" LOW LEVEL API

augroup vimproc
  autocmd VimLeave * call s:finalize()
  autocmd CursorHold,BufWritePost * call s:garbage_collect(0)
augroup END

" Initialize.
let s:lasterr = []
let s:read_timeout = 100
let s:write_timeout = 100
let s:bg_processes = {}

if vimproc#util#has_lua()
  function! s:split(str, sep)
    let result = []
    lua << EOF
    do
    local result = vim.eval('result')
    local str = vim.eval('a:str')
    local sep = vim.eval('a:sep')
    local last

    if string.find(str, sep, 1, true) == nil then
      result:add(str)
    else
      for part, pos in string.gmatch(str,
          '(.-)' .. sep .. '()') do
        result:add(part)
        last = pos
      end

      result:add(string.sub(str, last))
    end
  end
EOF

    return result
  endfunction
else
  function! s:split(str, sep)
    let [result, pos] = [[], 0]
    while 1
      let tmp = stridx(a:str, a:sep, pos)
      if tmp == -1
        call add(result, strpart(a:str, pos))
        break
      endif
      call add(result, strpart(a:str, pos, tmp - pos))
      let pos = tmp + 1
    endwhile

    return result
  endfunction
endif

function! s:libcall(func, args) "{{{
  " End Of Value
  let EOV = "\xFF"
  let args = empty(a:args) ? '' : (join(reverse(copy(a:args)), EOV) . EOV)
  let stack_buf = libcall(g:vimproc#dll_path, a:func, args)
  let result = s:split(stack_buf, EOV)
  if get(result, -1, 'error') != ''
    if stack_buf[len(stack_buf) - 1] ==# EOV
      " Note: If &encoding equals "cp932" and output ends multibyte first byte,
      "       will fail split.
      return result
    endif
    let s:lasterr = result
    let msg = vimproc#util#iconv(string(result),
          \ vimproc#util#termencoding(), &encoding)

    throw printf('vimproc: %s: %s', a:func, msg)
  endif
  return result[:-2]
endfunction"}}}

function! s:SID_PREFIX()
  if !exists('s:sid_prefix')
    let s:sid_prefix = matchstr(expand('<sfile>'),
          \ '<SNR>\d\+_\zeSID_PREFIX$')
  endif
  return s:sid_prefix
endfunction

" Get funcref.
function! s:funcref(funcname)
  return function(s:SID_PREFIX().a:funcname)
endfunction

function! s:finalize()
  call s:garbage_collect(1)

  if exists('s:dll_handle')
    call s:vp_dlclose(s:dll_handle)
  endif
endfunction

function! s:vp_dlopen(path)
  let [handle] = s:libcall('vp_dlopen', [a:path])
  return handle
endfunction

function! s:vp_dlclose(handle)
  call s:libcall('vp_dlclose', [a:handle])
endfunction

function! s:vp_file_open(path, flags, mode)
  let [fd] = s:libcall('vp_file_open', [a:path, a:flags, a:mode])
  return fd
endfunction

function! s:vp_file_close() dict
  if self.fd != 0
    call s:libcall('vp_file_close', [self.fd])
    let self.fd = 0
  endif
endfunction

function! s:vp_file_read(number, timeout) dict
  let [hd, eof] = s:libcall('vp_file_read', [self.fd, a:number, a:timeout])
  return [hd, eof]
endfunction

function! s:vp_file_write(hd, timeout) dict
  let [nleft] = s:libcall('vp_file_write', [self.fd, a:hd, a:timeout])
  return nleft
endfunction

function! s:quote_arg(arg)
  return (a:arg == '' || a:arg =~ '[ "]') ?
        \ '"' . substitute(a:arg, '"', '\\"', 'g') . '"' : a:arg
endfunction

function! s:vp_pipe_open(npipe, hstdin, hstdout, hstderr, argv) "{{{
  if vimproc#util#is_windows()
    let cmdline = s:quote_arg(substitute(a:argv[0], '/', '\', 'g'))
    for arg in a:argv[1:]
      let cmdline .= ' ' . s:quote_arg(arg)
    endfor
    let [pid; fdlist] = s:libcall('vp_pipe_open',
          \ [a:npipe, a:hstdin, a:hstdout, a:hstderr, cmdline])
  else
    let [pid; fdlist] = s:libcall('vp_pipe_open',
          \ [a:npipe, a:hstdin, a:hstdout, a:hstderr, len(a:argv)] + a:argv)
  endif

  if a:npipe != len(fdlist)
    call s:print_error(printf('a:npipe = %d, a:argv = %s', a:npipe, string(a:argv)))
    call s:print_error(printf('pid = %d, fdlist = %s', pid, string(fdlist)))
    echoerr 'Bug behavior is detected!: ' . pid
  endif

  return [pid] + fdlist
endfunction"}}}

function! s:vp_pipe_close() dict
  " echomsg 'close:'.self.fd
  if self.fd != 0
    call s:libcall('vp_pipe_close', [self.fd])
    let self.fd = 0
  endif
endfunction

function! s:vp_pipes_close() dict
  for fd in self.fd
    try
      call fd.close()
    catch /vimproc: vp_pipe_close: /
      " Ignore error.
    endtry
  endfor
endfunction

function! s:vp_pgroup_close() dict
  call self.fd.close()
endfunction

function! s:vp_pipe_read(number, timeout) dict
  if self.fd == 0
    return ['', 1]
  endif

  let [hd, eof] = s:libcall('vp_pipe_read', [self.fd, a:number, a:timeout])
  return [hd, eof]
endfunction

function! s:vp_pipe_write(hd, timeout) dict
  if self.fd == 0
    return 0
  endif

  let [nleft] = s:libcall('vp_pipe_write', [self.fd, a:hd, a:timeout])
  return nleft
endfunction

function! s:read_pipes(...) dict "{{{
  if type(self.fd[-1]) != type({})
    let self.eof = 1
    return ''
  endif

  let number = get(a:000, 0, -1)
  let timeout = get(a:000, 1, s:read_timeout)

  let output = self.fd[-1].read(number, timeout)
  let self.eof = self.fd[-1].eof

  return output
endfunction"}}}

function! s:write_pipes(str, ...) dict "{{{
  let timeout = get(a:000, 0, s:write_timeout)

  if self.fd[0].eof
    return 0
  endif

  " Write data.
  let nleft = self.fd[0].write(a:str, timeout)
  let self.eof = self.fd[0].eof

  return nleft
endfunction"}}}

function! s:read_pgroup(...) dict "{{{
  let number = get(a:000, 0, -1)
  let timeout = get(a:000, 1, s:read_timeout)

  let output = ''

  if !self.fd.eof
    let output = self.fd.read(number, timeout)
  endif

  if self.proc.current_proc.stdout.eof && self.proc.current_proc.stderr.eof
    " Get status.
    let [cond, status] = self.proc.current_proc.waitpid()

    if empty(self.proc.statements)
          \ || (self.proc.condition ==# 'true' && status)
          \ || (self.proc.condition ==# 'false' && !status)
      let self.proc.statements = []

      " Caching status.
      let self.proc.cond = cond
      let self.proc.status = status
    else
      " Initialize next statement.
      let proc = vimproc#plineopen3(self.proc.statements[0].statement)
      let self.proc.current_proc = proc

      let self.pid = proc.pid
      let self.pid_list = proc.pid_list
      let self.proc.pid = proc.pid
      let self.proc.pid_list = proc.pid_list
      let self.proc.condition = self.proc.statements[0].condition
      let self.proc.statements = self.proc.statements[1:]

      let self.proc.stdin = s:fdopen_pgroup(self.proc, proc.stdin, 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
      let self.proc.stdout = s:fdopen_pgroup(self.proc, proc.stdout, 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
      let self.proc.stderr = s:fdopen_pgroup(self.proc, proc.stderr, 'vp_pgroup_close', 'read_pgroup', 'write_pgroup')
    endif
  endif

  if self.proc.current_proc.stdout.eof
    let self.proc.stdout.eof = 1
    let self.proc.stdout.__eof = 1
  endif

  if self.proc.current_proc.stderr.eof
    let self.proc.stderr.eof = 1
    let self.proc.stderr.__eof = 1
  endif

  return output
endfunction"}}}

function! s:write_pgroup(str, ...) dict "{{{
  let timeout = get(a:000, 0, s:write_timeout)

  let nleft = 0
  if !self.fd.eof
    " Write data.
    let nleft = self.fd.write(a:str, timeout)
  endif

  return nleft
endfunction"}}}

function! s:vp_pty_open(npipe, width, height, hstdin, hstdout, hstderr, argv)
  let [pid; fdlist] = s:libcall('vp_pty_open',
        \ [a:npipe, a:width, a:height,
        \  a:hstdin, a:hstdout, a:hstderr, len(a:argv)] + a:argv)
  return [pid] + fdlist
endfunction

function! s:vp_pty_close() dict
  call s:libcall('vp_pty_close', [self.fd])
endfunction

function! s:vp_pty_read(number, timeout) dict
  let [hd, eof] = s:libcall('vp_pty_read', [self.fd, a:number, a:timeout])
  return [hd, eof]
endfunction

function! s:vp_pty_write(hd, timeout) dict
  let [nleft] = s:libcall('vp_pty_write', [self.fd, a:hd, a:timeout])
  return nleft
endfunction

function! s:vp_get_winsize() dict
  if self.is_pty && vimproc#util#is_windows()
    return [winwidth(0)-5, winheight(0)]
  endif

  for pid in self.pid_list
    let [width, height] = s:libcall('vp_pty_get_winsize', [pid])
  endfor

  return [width, height]
endfunction

function! s:vp_set_winsize(width, height) dict
  if vimproc#util#is_windows() || !self.is_valid
    " Not implemented.
    return
  endif

  if self.is_pty
    if self.stdin.eof == 0 && self.stdin.fd[-1].is_pty
      call s:libcall('vp_pty_set_winsize',
            \ [self.stdin.fd[-1].fd, a:width-5, a:height])
    endif
    if self.stdout.eof == 0 && self.stdout.fd[0].is_pty
      call s:libcall('vp_pty_set_winsize',
            \ [self.stdout.fd[0].fd, a:width-5, a:height])
    endif
    if self.stderr.eof == 0 && self.stderr.fd[0].is_pty
      call s:libcall('vp_pty_set_winsize',
            \ [self.stderr.fd[0].fd, a:width-5, a:height])
    endif
  endif

  " Send SIGWINCH = 28 signal.
  for pid in self.pid_list
    call vimproc#kill(pid, g:vimproc#SIGWINCH)
  endfor
endfunction

function! s:vp_kill(...) dict
  let sig = get(a:000, 0, g:vimproc#SIGTERM)
  if sig != 0
    call s:close_all(self)
    let self.is_valid = 0
  endif

  let ret = 0
  for pid in get(self, 'pid_list', [self.pid])
    let ret = vimproc#kill(pid, sig)
  endfor

  return ret
endfunction

function! s:vp_pgroup_kill(...) dict
  let sig = get(a:000, 0, g:vimproc#SIGTERM)
  if sig != 0
    call s:close_all(self)
    let self.is_valid = 0
  endif

  if self.pid == 0
    " Ignore.
    return
  endif

  return self.current_proc.kill(sig)
endfunction

function! s:waitpid(pid)
  try
    let [cond, status] = s:libcall('vp_waitpid', [a:pid])
    " echomsg string([a:pid, cond, status])
    if cond ==# 'run'
      " Add process list.
      let s:bg_processes[a:pid] = a:pid

      let [cond, status] = ['exit', '0']
    elseif vimproc#util#is_windows()
      call s:libcall('vp_close_handle', [a:pid])
    endif

    let s:last_status = status
  catch
    let [cond, status] = ['error', '0']
  endtry

  return [cond, str2nr(status)]
endfunction

function! s:vp_checkpid() dict
  try
    let [cond, status] = s:libcall('vp_waitpid', [self.pid])
    if cond !=# 'run'
      let [self.cond, self.status] = [cond, status]
    endif
  catch /waitpid() error:\|vp_waitpid:/
    let [cond, status] = ['error', '0']
  endtry

  return [cond, str2nr(status)]
endfunction

function! s:vp_waitpid() dict
  call s:close_all(self)

  let self.is_valid = 0

  if has_key(self, 'cond') && has_key(self, 'status')
    " Use cache.
    let [cond, status] = [self.cond, self.status]
  else
    let [cond, status] = s:waitpid(self.pid)
  endif

  if cond ==# 'exit'
    let self.pid = 0
  endif

  if has_key(self, 'pid_list')
    for pid in self.pid_list[: -2]
      call s:waitpid(pid)
    endfor
  endif

  return [cond, str2nr(status)]
endfunction

function! s:vp_pgroup_waitpid() dict
  call s:close_all(self)

  let self.is_valid = 0

  if !has_key(self, 'cond') ||
        \ !has_key(self, 'status')
    return s:waitpid(self.pid)
  endif

  return [self.cond, self.status]
endfunction

function! s:vp_socket_open(host, port)
  let [socket] = s:libcall('vp_socket_open', [a:host, a:port])
  return socket
endfunction

function! s:vp_socket_close() dict
  call s:libcall('vp_socket_close', [self.fd])
  let self.is_valid = 0
endfunction

function! s:vp_socket_read(number, timeout) dict
  let [hd, eof] = s:libcall('vp_socket_read',
        \ [self.fd, a:number, a:timeout])
  return [hd, eof]
endfunction

function! s:vp_socket_write(hd, timeout) dict
  let [nleft] = s:libcall('vp_socket_write',
        \ [self.fd, a:hd, a:timeout])
  return nleft
endfunction

function! s:vp_host_exists(host)
  let [rval] = s:libcall('vp_host_exists', [a:host])
  return rval
endfunction

" Initialize.
if !exists('s:dll_handle')
  let s:dll_handle = s:vp_dlopen(g:vimproc#dll_path)
  let s:last_status = 0
  let s:last_errmsg = ''
  call s:define_signals()
endif

" vimproc dll version check. "{{{
try
  let dll_version = vimproc#dll_version()
  if dll_version < vimproc#version()
    call s:print_error(printf('Your vimproc binary version is "%d",'.
          \ ' but vimproc version is "%d".',
          \ dll_version, vimproc#version()))
  endif
catch
  call s:print_error(v:throwpoint)
  call s:print_error(v:exception)
  call s:print_error('Your vimproc binary is too old!')
  call s:print_error('Please re-compile it.')
endtry

unlet dll_version
"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" __END__
" vim:foldmethod=marker:fen:sw=2:sts=2
