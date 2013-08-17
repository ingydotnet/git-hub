CMD := git-hub

LOCAL_LIB = lib/$(CMD)
LOCAL_EXT = $(shell find $(LOCAL_LIB).d -type f) \
	    $(shell find $(LOCAL_LIB).d -type l)

# XXX Make these vars look like git.git/Makefile style
PREFIX ?= /usr/local
INSTALL_LIB ?= $(shell git --exec-path)
INSTALL_MAN ?= $(PREFIX)/share/man/man1
INSTALL_EXT ?= $(INSTALL_LIB)/git-hub.d

# Submodules
JSON=ext/json-bash/lib/json.bash
TEST_SIMPLE=ext/test-simple-bash/lib/test-simple.bash
SUBMODULE := $(JSON) $(TEST_SIMPLE)

## XXX assert good bash

##
# Make sure we have 'git' and it works OK.
ifeq ($(shell which git),)
    $(error 'git' is not installed on this system)
endif
GITVER ?= $(word 3,$(shell git --version))

##
# User targets:
.PHONY: default help test
default: help

help:
	@echo 'Makefile rules:'
	@echo ''
	@echo 'test       Run all tests'
	@echo 'install    Install $(CMD)'
	@echo 'uninstall  Uninstall $(CMD)'

test: $(SUBMODULE)
ifeq ($(shell which prove),)
	@echo '`make test` requires the `prove` utility'
	@exit 1
endif
	prove $(PROVE_OPTIONS) test/

.PHONY: install install-lib install-doc
install: install-lib install-doc

install-lib: $(SUBMODULE) $(INSTALL_EXT)
	install -C -m 0755 $(LOCAL_LIB) $(INSTALL_LIB)/
	install -C -d -m 0755 $(INSTALL_EXT)/
	install -C -m 0755 $(LOCAL_EXT) $(INSTALL_EXT)/

install-doc:
	install -C -d -m 0755 $(INSTALL_MAN)
	install -C -m 0644 doc/$(CMD).1 $(INSTALL_MAN)

.PHONY: uninstall uninstall-lib uninstall-doc
uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -f $(INSTALL_LIB)/$(CMD)
	rm -fr $(INSTALL_EXT)/

uninstall-doc:
	rm -f $(INSTALL_MAN)/$(CMD).1

$(INSTALL_EXT):
	mkdir -p $@

##
# Sanity checks:
$(SUBMODULE):
	@echo 'You need to run `git submodule update --init` first.' >&2
	@exit 1

##
# Build rules:
.PHONY: doc
doc: doc/$(CMD).1

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

##
# Undocumented dev rules

# Install using symlinks so repo changes can be tested live
.PHONY: dev-install dev-test dev-test-reset check-dev-install
dev-install: $(SUBMODULE) uninstall-lib $(INSTALL_EXT)
	ln -s $$PWD/lib/$(CMD) $(INSTALL_LIB)/$(CMD)
	chmod 0755 $(INSTALL_EXT)/
	@for ext in $(LOCAL_EXT); do \
	    echo "ln -s $$PWD/$$ext $(INSTALL_EXT)/$${ext#lib/git-hub.d/}"; \
	    ln -s $$PWD/$$ext $(INSTALL_EXT)/$${ext#lib/git-hub.d/}; \
	done

# Run a bunch of live tests. Make sure this thing really works. :)
dev-test: check-dev-install
	bash test/dev-test/all_commands.t
	bash test/dev-test/each.t

# Run this to reset if `make dev-test` fails.
dev-test-reset: check-dev-install
	GIT_HUB_TEST_RESET=1 bash test/dev-test/all_commands.t

check-dev-install:
	@if [ ! -L $(INSTALL_LIB)/$(CMD) ]; then \
	    echo "Run 'make dev-install' first"; \
	    exit 1; \
	fi

