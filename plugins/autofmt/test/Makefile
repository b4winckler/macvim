VIMPROG = vim

SCRIPTS := $(patsubst %.ok, %.out, $(wildcard *.ok))

.SUFFIXES: .in .out

all: nolog $(SCRIPTS) report

report:
	@echo
	@echo 'Test results:'
	@/bin/sh -c "if test -f test.log; \
		then cat test.log; echo TEST FAILURE; exit 1; \
		else echo ALL DONE; \
		fi"

clean:
	-rm -rf *.out *.failed test.log test.ok X* debug.log

.in.out:
	-rm -rf $*.failed test.ok test.out X*
	cp $*.ok test.ok
	# Sleep a moment to avoid that the xterm title is messed up
	@-sleep .2
	-$(VIMPROG) -u unix.vim -U NONE --noplugin -s dotest.in $*.in
	@/bin/sh -c "if test -f test.out; then\
		  if diff test.out $*.ok; \
		  then mv -f test.out $*.out; \
		  else echo $* FAILED >>test.log; mv -f test.out $*.failed; \
		  fi \
		else echo $* NO OUTPUT >>test.log; \
		fi"
	-rm -rf X* test.ok

nolog:
	-rm -f test.log
