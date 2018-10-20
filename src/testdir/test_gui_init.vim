" Tests specifically for the GUI features/options that need to be set up at
" startup to take effect at runtime.

if !has('gui') || ($DISPLAY == "" && !has('gui_running'))
  finish
endif

source setup_gui.vim

func Setup()
  call GUISetUpCommon()
endfunc

func TearDown()
  call GUITearDownCommon()
endfunc

" Ignore the "failed to create input context" error.
call test_ignore_error('E285')

" Start the GUI now, in the foreground.
gui -f

func Test_set_guiheadroom()
  let skipped = ''

  if !g:x11_based_gui
    let skipped = g:not_supported . 'guiheadroom'
  else
    " The 'expected' value must be consistent with the value specified with
    " gui_init.vim.
    call assert_equal(0, &guiheadroom)
  endif

  if !empty(skipped)
    throw skipped
  endif
endfunc

func Test_set_guioptions_for_M()
  sleep 200ms
  " Check if the 'M' option is included.
  call assert_match('.*M.*', &guioptions)
endfunc

func Test_set_guioptions_for_p()
  let skipped = ''

  if !g:x11_based_gui
    let skipped = g:not_supported . '''p'' of guioptions'
  else
    sleep 200ms
    " Check if the 'p' option is included.
    call assert_match('.*p.*', &guioptions)
  endif

  if !empty(skipped)
    throw skipped
  endif
endfunc
