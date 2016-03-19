" Test that the methods used for testing work.

func Test_assert_false()
  call assert_false(0)
  call assert_false(v:false)
endfunc

func Test_assert_true()
  call assert_true(1)
  call assert_true(123)
  call assert_true(v:true)
endfunc

func Test_assert_equal()
  let s = 'foo'
  call assert_equal('foo', s)
  let n = 4
  call assert_equal(4, n)
  let l = [1, 2, 3]
  call assert_equal([1, 2, 3], l)
endfunc

func Test_assert_exception()
  try
    nocommand
  catch
    call assert_exception('E492:')
  endtry

  try
    nocommand
  catch
    try
      " illegal argument, get NULL for error
      call assert_exception([])
    catch
      call assert_exception('E730:')
    endtry
  endtry
endfunc

func Test_wrong_error_type()
  let save_verrors = v:errors
  let v:['errors'] = {'foo': 3}
  call assert_equal('yes', 'no')
  let verrors = v:errors
  let v:errors = save_verrors
  call assert_equal(type([]), type(verrors))
endfunc

func Test_compare_fail()
  let s:v = {}          
  let s:x = {"a": s:v} 
  let s:v["b"] = s:x   
  let s:w = {"c": s:x, "d": ''}
  try
    call assert_equal(s:w, '')
  catch
    call assert_exception('E724:')
    call assert_true(v:errors[0] =~ "Expected NULL but got ''")
    call remove(v:errors, 0)
  endtry
endfunc

func Test_assert_fail_fails()
  call assert_fails('xxx', {})
  call assert_true(v:errors[0] =~ "Expected {} but got 'E731:")
  call remove(v:errors, 0)
endfunc


func Test_user_is_happy()
  smile
  sleep 300m
endfunc
