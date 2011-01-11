
DISTFILES = \
	    Makefile \
	    README \
	    memo.txt \
	    autoload/autofmt/compat.vim \
	    autoload/autofmt/japanese.vim \
	    autoload/autofmt/uax14.vim \
	    autoload/unicode.vim \
	    doc/autofmt.txt \
	    test/Makefile \
	    test/dotest.in \
	    test/test1.in \
	    test/test1.ok \
	    test/test2.in \
	    test/test2.ok \
	    test/test3.in \
	    test/test3.ok \
	    test/unix.vim

.PHONY: package test clean

all: package

package: clean test
	mkdir autofmt
	cp --parents $(DISTFILES) autofmt
	rm -f autofmt.zip
	zip -r autofmt.zip autofmt
	rm -r autofmt

test:
	cd test && $(MAKE)

clean:
	cd test && $(MAKE) clean

