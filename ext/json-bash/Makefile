CMD := json.bash

PREFIX ?= /usr/local
INSTALL_LIB ?= $(PREFIX)/lib/bash
INSTALL_MAN ?= $(PREFIX)/share/man/man1

# Submodules
TEST_MORE := ext/test-more-bash/lib/test/more.bash

##
# User targets:
default: help

help:
	@echo 'Makefile rules:'
	@echo ''
	@echo 'test       Run all tests'
	@echo 'install    Install $(CMD)'
	@echo 'uninstall  Uninstall $(CMD)'
	@echo 'clean      Remove build/test files'

.PHONY: test
test: $(TEST_MORE)
	prove $(PROVEOPT) test/

install: $(INSTALL_LIB)
	install -m 0755 lib/$(CMD) $(INSTALL_LIB)/
	install -c -d -m 0755 $(INSTALL_MAN)/
	install -c -m 0644 man/man1/$(CMD).1 $(INSTALL_MAN)/

uninstall:
	rm -f $(INSTALL_LIB)/$(CMD)
	rm -f $(INSTALL_MAN)/$(CMD).1

clean purge:
	true

# Builder rules:
.PHONY: doc
doc: ReadMe.pod man/man1/json.1

ReadMe.pod: doc/json.swim
	swim --to=pod --wrap --complete $< > $@

man/man1/json.1: doc/json.swim
	swim --to=man $< > $@

$(INSTALL_LIB):
	mkdir -p $@
