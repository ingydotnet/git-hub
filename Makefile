.PHONY: default help build doc test \
    install install-lib install-doc \
    uninstall uninstall-lib uninstall-doc \
    dev-test dev-install dev-test-reset check-dev-install

CMD := git-hub
TMP := ./tmp

PREFIX ?= /usr/local
INSTALL_LIB ?= $(shell git --exec-path)
ifeq ($(INSTALL_LIB),)
    $(error Cannot determine location of git commands)
endif
INSTALL_MAN ?= $(PREFIX)/share/man/man1

# Submodules
JSON=ext/json-bash/lib/json.bash
TEST_SIMPLE=ext/test-simple-bash/lib/test-simple.bash
SUBMODULE := $(JSON) $(TEST_SIMPLE)

##
# Make sure we have 'git' and it works OK.
GIT ?= $(shell which git)
ifeq ($(GIT),)
    $(error 'git' is not installed on this system)
endif
GITVER ?= $(word 3,$(shell git --version))

##
# User targets:
default: help

help:
	@echo 'Makefile rules:'
	@echo ''
	@echo 'build      Build $(CMD)'
	@echo 'test       Run all tests'
	@echo 'install    Install $(CMD)'
	@echo 'uninstall  Uninstall $(CMD)'
	@echo 'clean      Remove build/test files'

build: lib/$(CMD) lib/$(CMD)./json.bash

test: build $(TEST_SIMPLE)
	prove $(PROVE_OPTIONS) test/

install: install-lib install-doc

install-lib: build uninstall-lib $(INSTALL_LIB)/$(CMD)./
	install -m 0755 lib/$(CMD) $(INSTALL_LIB)/
	install -d -m 0755 $(INSTALL_LIB)/$(CMD)./
	install -m 0755 lib/$(CMD)./* $(INSTALL_LIB)/$(CMD)./

install-doc:
	install -c -d -m 0755 $(INSTALL_MAN)
	install -c -m 0644 doc/$(CMD).1 $(INSTALL_MAN)

uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -f $(INSTALL_LIB)/$(CMD)
	rm -fr $(INSTALL_LIB)/$(CMD).

uninstall-doc:
	rm -f $(INSTALL_MAN)/$(CMD).1

$(INSTALL_LIB)/$(CMD)./:
	mkdir -p $@

clean purge:
	rm -fr lib/$(CMD)./json.bash $(CMD).* $(TMP) /tmp/$(CMD)-*

##
# Sanity checks:
$(SUBMODULE):
	@echo 'You need to run `git submodule update --init` first.' >&2
	@exit 1

##
# Build rules:
doc: doc/$(CMD).1

lib/$(CMD)./json.bash: $(JSON) lib/$(CMD).
	cp $< $@

$(CMD).txt: readme.asc
	cp $< $@

%.xml: %.txt
	asciidoc -b docbook -d manpage -f doc/asciidoc.conf \
		-agit_version=$(GITVER) $^
	rm $<

%.1: %.xml
	xmlto -m doc/manpage-normal.xsl man $^

doc/%.1: %.1
	mv $< $@

lib/$(CMD).:
	mkdir $@

##
# Undocumented dev rules

# Install using symlinks so repo changes can be tested live
dev-install: build uninstall-lib
	ln -s $$PWD/lib/$(CMD) $(INSTALL_LIB)/$(CMD)
	ln -s $$PWD/lib/$(CMD). $(INSTALL_LIB)/$(CMD).

# Run a bunch of live tests. Make sure this thing really works. :)
dev-test: check-dev-install
	bash test/dev-test/all_commands.t

# Run this to reset if `make dev-test` fails.
dev-test-reset: check-dev-install
	GIT_HUB_TEST_RESET=1 bash test/dev-test/all_commands.t

check-dev-install:
	@if [ ! -L $$(git --exec-path)/git-hub ]; then \
	    echo "Run 'make dev-install' first"; \
	    exit 1; \
	fi

