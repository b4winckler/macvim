" Settings for test script execution
" Always use "sh", don't use the value of "$SHELL".
let g:__vimrc = expand("<sfile>:p")
set shell=sh
set debug=msg
set verbosefile=debug.log
let &runtimepath = expand("<sfile>:p:h:h")
