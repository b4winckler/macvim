
.PHONY: dist test clean

all: dist

dist: clean test
	svn export . autofmt
	rm -f autofmt.zip
	zip -r autofmt.zip autofmt
	rm -r autofmt

test:
	cd test && $(MAKE)

clean:
	cd test && $(MAKE) clean

