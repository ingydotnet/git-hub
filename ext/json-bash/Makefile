.PHONY: default help doc test \
    install install-lib install-doc \
    uninstall uninstall-lib uninstall-doc

CMD := json.bash

# XXX This is a very crude default. Be smarter here…
PREFIX ?= /usr/local
INSTALL_LIB ?= $(PREFIX)/lib/bash
INSTALL_MAN ?= $(PREFIX)/share/man/man1

# Submodules
TEST_MORE := ext/test-more-bash/lib/test/more.bash
SUBMODULE := $(TEST_MORE)

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

test: $(TEST_MORE)
	prove $(PROVEOPT) test/

install: install-lib install-doc

install-lib: $(INSTALL_LIB)
	install -m 0755 lib/$(CMD) $(INSTALL_LIB)/

install-doc:
	install -c -d -m 0755 $(INSTALL_MAN)
	install -c -m 0644 doc/$(CMD).1 $(INSTALL_MAN)

uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -f $(INSTALL_LIB)/$(CMD)

uninstall-doc:
	rm -f $(INSTALL_MAN)/$(CMD).1

clean purge:
	true

##
# Sanity checks:
$(SUBMODULE):
	git submodule update --init --recursive

##
# Builder rules:
.PHONY: doc
doc: doc/json.1

%.1: %.md
	ronn --roff < $< > $@

doc/%.1: %.1
	mv $< $@

$(INSTALL_LIB):
	mkdir -p $@
