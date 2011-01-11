" Settings for test script execution
" Always use "sh", don't use the value of "$SHELL".
set shell=sh
set debug=msg
let &runtimepath = expand("%:p:h:h")
