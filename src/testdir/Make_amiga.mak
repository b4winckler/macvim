#
# Makefile to run all tests for Vim, on Amiga
#
# Requires "rm", "csh" and "diff"!

VIMPROG = /vim

# These tests don't work (yet):
# test2		"\\tmp" doesn't work
# test10	'errorformat' is different
# test11	"cat" doesn't work properly
# test12	can't unlink a swap file
# test25	uses symbolic link
# test27	can't edit file with "*"
# test52	only for Win32
# test85	no Lua interface
# test86, 87	no Python interface

SCRIPTS = test1.out test3.out test4.out test5.out test6.out \
		test7.out test8.out test9.out \
		test13.out test14.out test15.out test17.out \
		test18.out test19.out test20.out test21.out test22.out \
		test23.out test24.out test26.out \
		test28.out test29.out test30.out test31.out test32.out \
		test33.out test34.out test35.out test36.out test37.out \
		test38.out test39.out test40.out test41.out test42.out \
		test43.out test44.out test45.out test46.out test47.out \
		test48.out test51.out test53.out test54.out test55.out \
		test56.out test57.out test58.out test59.out test60.out \
		test61.out test62.out test63.out test64.out test65.out \
		test66.out test67.out test68.out test69.out test70.out \
		test71.out test72.out test73.out test74.out test75.out \
		test76.out test77.out test78.out test79.out test80.out \
		test81.out test82.out test83.out test84.out test88.out \
		test89.out test90.out test91.out test92.out test93.out \
		test94.out test95.out test96.out test97.out test98.out \
		test99.out test100.out test101.out test102.out test103.out \
		test104.out test105.out test106.out \
		test_autoformat_join.out \
		test_eval.out \
		test_options.out

.SUFFIXES: .in .out

nongui:	/tmp $(SCRIPTS)
	csh -c echo ALL DONE

clean:
	csh -c \rm -rf *.out /tmp/* Xdotest small.vim tiny.vim mbyte.vim test.ok viminfo

.in.out:
	copy $*.ok test.ok
	$(VIMPROG) -u amiga.vim -U NONE --noplugin -s dotest.in $*.in
	diff test.out $*.ok
	rename test.out $*.out
	-delete X#? ALL QUIET
	-delete test.ok

# Create a directory for temp files
/tmp:
	makedir /tmp

# Manx requires all dependencies...
test1.out: test1.in
test2.out: test2.in
test3.out: test3.in
test4.out: test4.in
test5.out: test5.in
test6.out: test6.in
test7.out: test7.in
test8.out: test8.in
test9.out: test9.in
test10.out: test10.in
test11.out: test11.in
test12.out: test12.in
test13.out: test13.in
test14.out: test14.in
test15.out: test15.in
test16.out: test16.in
test17.out: test17.in
test18.out: test18.in
test19.out: test19.in
test20.out: test20.in
test21.out: test21.in
test22.out: test22.in
test23.out: test23.in
test24.out: test24.in
test25.out: test25.in
test26.out: test26.in
test27.out: test27.in
test28.out: test28.in
test29.out: test29.in
test30.out: test30.in
test31.out: test31.in
test32.out: test32.in
test33.out: test33.in
test34.out: test34.in
test35.out: test35.in
test36.out: test36.in
test37.out: test37.in
test38.out: test38.in
test39.out: test39.in
test40.out: test40.in
test41.out: test41.in
test42.out: test42.in
test43.out: test43.in
test44.out: test44.in
test45.out: test45.in
test46.out: test46.in
test47.out: test47.in
test48.out: test48.in
test51.out: test51.in
test53.out: test53.in
test54.out: test54.in
test55.out: test55.in
test56.out: test56.in
test57.out: test57.in
test58.out: test58.in
test59.out: test59.in
test60.out: test60.in
test61.out: test61.in
test62.out: test62.in
test63.out: test63.in
test64.out: test64.in
test65.out: test65.in
test66.out: test66.in
test67.out: test67.in
test68.out: test68.in
test69.out: test69.in
test70.out: test70.in
test71.out: test71.in
test72.out: test72.in
test73.out: test73.in
test74.out: test74.in
test75.out: test75.in
test76.out: test76.in
test77.out: test77.in
test78.out: test78.in
test79.out: test79.in
test80.out: test80.in
test81.out: test81.in
test82.out: test82.in
test83.out: test83.in
test84.out: test84.in
test88.out: test88.in
test89.out: test89.in
test90.out: test90.in
test91.out: test91.in
test92.out: test92.in
test93.out: test93.in
test94.out: test94.in
test95.out: test95.in
test96.out: test96.in
test97.out: test97.in
test98.out: test98.in
test99.out: test99.in
test100.out: test100.in
test101.out: test101.in
test102.out: test102.in
test103.out: test103.in
test104.out: test104.in
test105.out: test105.in
test106.out: test106.in
test_autoformat_join.out: test_autoformat_join.in
test_eval.out: test_eval.in
test_options.out: test_options.in
