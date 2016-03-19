" Test sort()

:func Compare1(a, b) abort
    call sort(range(3), 'Compare2')
    return a:a - a:b
:endfunc

:func Compare2(a, b) abort
    return a:a - a:b
:endfunc

func Test_sort_strings()
  " numbers compared as strings
  call assert_equal([1, 2, 3], sort([3, 2, 1]))
  call assert_equal([13, 28, 3], sort([3, 28, 13]))
endfunc

func Test_sort_numeric()
  call assert_equal([1, 2, 3], sort([3, 2, 1], 'n'))
  call assert_equal([3, 13, 28], sort([13, 28, 3], 'n'))
  " strings are not sorted
  call assert_equal(['13', '28', '3'], sort(['13', '28', '3'], 'n'))
endfunc

func Test_sort_numbers()
  call assert_equal([3, 13, 28], sort([13, 28, 3], 'N'))
  call assert_equal(['3', '13', '28'], sort(['13', '28', '3'], 'N'))
endfunc

func Test_sort_float()
  call assert_equal([0.28, 3, 13.5], sort([13.5, 0.28, 3], 'f'))
endfunc

func Test_sort_nested()
  " test ability to call sort() from a compare function
  call assert_equal([1, 3, 5], sort([3, 1, 5], 'Compare1'))
endfunc

func Test_sort_default()
  " docs say omitted, empty or zero argument sorts on string representation.
  call assert_equal(['2', 'A', 'AA', 'a', 1, 3.3], sort([3.3, 1, "2", "A", "a", "AA"]))
  call assert_equal(['2', 'A', 'AA', 'a', 1, 3.3], sort([3.3, 1, "2", "A", "a", "AA"], ''))
  call assert_equal(['2', 'A', 'AA', 'a', 1, 3.3], sort([3.3, 1, "2", "A", "a", "AA"], 0))
  call assert_equal(['2', 'A', 'a', 'AA', 1, 3.3], sort([3.3, 1, "2", "A", "a", "AA"], 1))
  call assert_fails('call sort([3.3, 1, "2"], 3)', "E474")
endfunc
