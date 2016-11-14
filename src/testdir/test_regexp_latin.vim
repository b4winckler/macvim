" Tests for regexp in latin1 encoding
set encoding=latin1
scriptencoding latin1

func s:equivalence_test()
  let str = "A������ B C D E���� F G H I���� J K L M N� O������ P Q R S T U���� V W X Y� Z a������ b c d e���� f g h i���� j k l m n� o������ p q r s t u���� v w x y�� z"
  let groups = split(str)
  for group1 in groups
      for c in split(group1, '\zs')
	" next statement confirms that equivalence class matches every
	" character in group
        call assert_match('^[[=' . c . '=]]*$', group1)
        for group2 in groups
          if group2 != group1
	    " next statement converts that equivalence class doesn't match
	    " a character in any other group
            call assert_equal(-1, match(group2, '[[=' . c . '=]]'))
          endif
        endfor
      endfor
  endfor
endfunc

func Test_equivalence_re1()
  set re=1
  call s:equivalence_test()
endfunc

func Test_equivalence_re2()
  set re=2
  call s:equivalence_test()
endfunc

func Test_recursive_substitute()
  new
  s/^/\=execute("s#^##gn")
  " check we are now not in the sandbox
  call setwinvar(1, 'myvar', 1)
  bwipe!
endfunc

func Test_nested_backrefs()
  " Check example in change.txt.
  new
  for re in range(0, 2)
    exe 'set re=' . re
    call setline(1, 'aa ab x')
    1s/\(\(a[a-d] \)*\)\(x\)/-\1- -\2- -\3-/
    call assert_equal('-aa ab - -ab - -x-', getline(1))

    call assert_equal('-aa ab - -ab - -x-', substitute('aa ab x', '\(\(a[a-d] \)*\)\(x\)', '-\1- -\2- -\3-', ''))
  endfor
  bwipe!
  set re=0
endfunc

func Test_eow_with_optional()
  let expected = ['abc def', 'abc', 'def', '', '', '', '', '', '', '']
  for re in range(0, 2)
    exe 'set re=' . re
    let actual = matchlist('abc def', '\(abc\>\)\?\s*\(def\)')
    call assert_equal(expected, actual)
  endfor
endfunc
