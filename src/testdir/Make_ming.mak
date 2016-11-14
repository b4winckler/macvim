#
# Makefile to run all tests for Vim, on Dos-like machines
# with sh.exe or zsh.exe in the path or not.
#
# Author: Bill McCarthy
#
# Note that test54 has been removed until it is fixed.
#
# Requires a set of Unix tools: echo, diff, etc.

ifneq (sh.exe, $(SHELL))
DEL = rm -f
DELDIR = rm -rf
MV = mv
CP = cp
CAT = cat
DIRSLASH = /
else
DEL = del
DELDIR = rd /s /q
MV = rename
CP = copy
CAT = type
DIRSLASH = \\
endif

VIMPROG = ..$(DIRSLASH)vim

default: vimall

include Make_all.mak

# Omitted:
# test2		"\\tmp" doesn't work.
# test10	'errorformat' is different
# test12	can't unlink a swap file
# test25	uses symbolic link
# test54	doesn't work yet
# test97	\{ and \$ are not escaped characters

SCRIPTS = $(SCRIPTS_ALL) $(SCRIPTS_MORE1) $(SCRIPTS_MORE4) $(SCRIPTS_WIN32)

SCRIPTS_BENCH = bench_re_freeze.out

# Must run test1 first to create small.vim.
$(SCRIPTS) $(SCRIPTS_GUI) $(SCRIPTS_WIN32) $(NEW_TESTS): $(SCRIPTS_FIRST)

.SUFFIXES: .in .out .res .vim

vimall:	fixff $(SCRIPTS_FIRST) $(SCRIPTS) $(SCRIPTS_GUI) $(SCRIPTS_WIN32) newtests
	@echo ALL DONE

nongui:	fixff nolog $(SCRIPTS_FIRST) $(SCRIPTS) newtests
	@echo ALL DONE

benchmark: $(SCRIPTS_BENCH)

small: nolog
	@echo ALL DONE

gui:	fixff nolog $(SCRIPTS_FIRST) $(SCRIPTS) $(SCRIPTS_GUI) newtests
	@echo ALL DONE

win32:	fixff nolog $(SCRIPTS_FIRST) $(SCRIPTS) $(SCRIPTS_WIN32) newtests
	@echo ALL DONE

# TODO: find a way to avoid changing the distributed files.
fixff:
	-$(VIMPROG) -u dos.vim $(NO_PLUGIN) "+argdo set ff=dos|upd" +q *.in *.ok
	-$(VIMPROG) -u dos.vim $(NO_PLUGIN) "+argdo set ff=unix|upd" +q \
		dotest.in test60.ok test_listchars.ok \
		test_getcwd.ok test_wordcount.ok

clean:
	-@if exist *.out $(DEL) *.out
	-@if exist *.failed $(DEL) *.failed
	-@if exist *.res $(DEL) *.res
	-@if exist test.in $(DEL) test.in
	-@if exist test.ok $(DEL) test.ok
	-@if exist small.vim $(DEL) small.vim
	-@if exist tiny.vim $(DEL) tiny.vim
	-@if exist mbyte.vim $(DEL) mbyte.vim
	-@if exist mzscheme.vim $(DEL) mzscheme.vim
	-@if exist lua.vim $(DEL) lua.vim
	-@if exist Xdir1 $(DELDIR) Xdir1
	-@if exist Xfind $(DELDIR) Xfind
	-@if exist X* $(DEL) X*
	-@if exist viminfo $(DEL) viminfo
	-@if exist test.log $(DEL) test.log
	-@if exist messages $(DEL) messages

.in.out:
	-@if exist $*.ok $(CP) $*.ok test.ok
	$(VIMPROG) -u dos.vim $(NO_PLUGIN) -s dotest.in $*.in
	@diff test.out $*.ok
	-@if exist $*.out $(DEL) $*.out
	@$(MV) test.out $*.out
	-@if exist Xdir1 $(DELDIR) Xdir1
	-@if exist Xfind $(DELDIR) Xfind
	-@if exist X* $(DEL) X*
	-@if exist test.ok $(DEL) test.ok
	-@if exist viminfo $(DEL) viminfo

nolog:
	-@if exist test.log $(DEL) test.log
	-@if exist messages $(DEL) messages

bench_re_freeze.out: bench_re_freeze.vim
	-$(DEL) benchmark.out
	$(VIMPROG) -u dos.vim $(NO_PLUGIN) $*.in
	$(CAT) benchmark.out

# New style of tests uses Vim script with assert calls.  These are easier
# to write and a lot easier to read and debug.
# Limitation: Only works with the +eval feature.

newtests: $(NEW_TESTS)

.vim.res:
	@echo "$(VIMPROG)" > vimcmd
	$(VIMPROG) -u NONE $(NO_PLUGIN) -S runtest.vim $*.vim
	@$(DEL) vimcmd

