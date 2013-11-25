#
# Makefile to run all tests for Vim, on Dos-like machines.
#
# Requires a set of Unix tools: echo, diff, etc.

VIMPROG = ..\\vim

# Omitted:
# test2		"\\tmp" doesn't work.
# test10	'errorformat' is different
# test12	can't unlink a swap file
# test25	uses symbolic link
# test27	can't edit file with "*" in file name
# test97	\{ and \$ are not escaped characters.

SCRIPTS16 =	test1.out test19.out test20.out test22.out \
		test23.out test24.out test28.out test29.out \
		test35.out test36.out test43.out \
		test44.out test45.out test46.out test47.out \
		test48.out test51.out test53.out test54.out \
		test55.out test56.out test57.out test58.out test59.out \
		test60.out test61.out test62.out test63.out test64.out

SCRIPTS =	test3.out test4.out test5.out test6.out test7.out \
		test8.out test9.out test11.out test13.out test14.out \
		test15.out test17.out test18.out test21.out test26.out \
		test30.out test31.out test32.out test33.out test34.out \
		test37.out test38.out test39.out test40.out test41.out \
		test42.out test52.out test65.out test66.out test67.out \
		test68.out test69.out test71.out test72.out test73.out \
		test74.out test75.out test76.out test77.out test78.out \
		test79.out test80.out test81.out test82.out test83.out \
		test84.out test85.out test86.out test87.out test88.out \
		test89.out test90.out test91.out test92.out test93.out \
		test94.out test95.out test96.out test98.out test99.out \
		test100.out test101.out test102.out test103.out

SCRIPTS32 =	test50.out test70.out

SCRIPTS_GUI =	test16.out

TEST_OUTFILES = $(SCRIPTS16) $(SCRIPTS) $(SCRIPTS32) $(SCRIPTS_GUI)
DOSTMP = dostmp
DOSTMP_OUTFILES = $(TEST_OUTFILES:test=dostmp\test)
DOSTMP_INFILES = $(DOSTMP_OUTFILES:.out=.in)

.SUFFIXES: .in .out

nongui:	clear_report $(SCRIPTS16) $(SCRIPTS) report

small:	clear_report report

gui:	clear_report $(SCRIPTS16) $(SCRIPTS) $(SCRIPTS_GUI) report

win32:	clear_report $(SCRIPTS16) $(SCRIPTS) $(SCRIPTS32) report

$(DOSTMP_INFILES): $(*B).in
	IF NOT EXIST $(DOSTMP)\NUL MD $(DOSTMP)
	IF EXIST $@ DEL $@
	$(VIMPROG) -u dos.vim --noplugin "+set ff=dos|f $@|wq" $(*B).in

$(DOSTMP_OUTFILES): $*.in
	-@IF EXIST test.out DEL test.out
	MOVE $(*B).in $(*B).in.bak
	COPY $*.in $(*B).in
	COPY $(*B).ok test.ok
	$(VIMPROG) -u dos.vim -U NONE --noplugin -s dotest.in $(*B).in
	-@IF EXIST test.out MOVE /y test.out $@
	-@IF EXIST $(*B).in.bak \
		( DEL $(*B).in & MOVE $(*B).in.bak $(*B).in )
	-@IF EXIST test.in DEL test.in
	-@IF EXIST X* DEL X*
	-@IF EXIST test.ok DEL test.ok
	-@IF EXIST Xdir1 RD /s /q Xdir1
	-@IF EXIST Xfind RD /s /q Xfind
	-@IF EXIST viminfo DEL viminfo

$(TEST_OUTFILES): $(DOSTMP)\$(*B).out
	IF EXIST test.out DEL test.out
	$(VIMPROG) -u dos.vim --noplugin "+set ff=unix|f test.out|wq" \
		$(DOSTMP)\$(*B).out
	@diff test.out $*.ok & IF ERRORLEVEL 1 \
		( MOVE /y test.out $*.failed \
		 & DEL $(DOSTMP)\$(*B).out \
		 & ECHO $* FAILED >> test.log ) \
		ELSE ( MOVE /y test.out $*.out )

fixff:
	-$(VIMPROG) -u dos.vim --noplugin "+argdo set ff=dos|upd" +q *.in *.ok
	-$(VIMPROG) -u dos.vim --noplugin "+argdo set ff=unix|upd" +q \
		dotest.in test60.ok test71.ok test74.ok

report:
	@ECHO ""
	@ECHO Test results:
	@IF EXIST test.log ( TYPE test.log & ECHO TEST FAILURE & EXIT /b 1 ) \
		ELSE ( ECHO ALL DONE )

clean:
	-IF EXIST *.out DEL *.out
	-IF EXIST *.failed DEL *.failed
	-IF EXIST $(DOSTMP) RD /s /q $(DOSTMP)
	-IF EXIST test.in DEL test.in
	-IF EXIST test.ok DEL test.ok
	-IF EXIST test.log DEL test.log
	-IF EXIST small.vim DEL small.vim
	-IF EXIST tiny.vim DEL tiny.vim
	-IF EXIST mbyte.vim DEL mbyte.vim
	-IF EXIST mzscheme.vim DEL mzscheme.vim
	-IF EXIST lua.vim DEL lua.vim
	-IF EXIST X* DEL X*
	-IF EXIST Xdir1 RD /s /q Xdir1
	-IF EXIST Xfind RD /s /q Xfind
	-IF EXIST viminfo DEL viminfo

clear_report:
	-IF EXIST test.log DEL test.log
