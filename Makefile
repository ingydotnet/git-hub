.PHONY: default help build doc test install install-all install-exe install-doc dev-install dev-test dev-test-reset check-dev-install

##
# Make sure we have 'git' and it works OK.
GIT ?= $(shell which git)
ifeq ($(GIT),)
    $(error 'git' is not installed on this system)
endif
GIT_INSTALL_LIB ?= $(shell git --exec-path)
ifeq ($(GIT_INSTALL_LIB),)
    $(error Cannot determine location of git commands)
endif
MAN1DIR ?= /usr/local/share/man/man1
GITVER ?= $(word 3,$(shell git --version))

##
# Define common variables
CMD := git-hub
TMP := ./tmp

##
# User facing rules start here:
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
doc: doc/$(CMD).1

test: build ext/bash-tap/bash-tap
	prove test/

install: uninstall install-exe install-doc

install-exe: build $(GIT_INSTALL_LIB)/$(CMD)./
	install -m 0755 lib/$(CMD) $(GIT_INSTALL_LIB)/
	install -d -m 0755 $(GIT_INSTALL_LIB)/$(CMD)./
	install -m 0755 lib/$(CMD)./* $(GIT_INSTALL_LIB)/$(CMD)./

install-doc:
	install -c -d -m 0755 $(MAN1DIR)
	install -c -m 0644 doc/$(CMD).1 $(MAN1DIR)

uninstall:
	rm -f $(GIT_INSTALL_LIB)/$(CMD)
	rm -fr $(GIT_INSTALL_LIB)/$(CMD).

$(GIT_INSTALL_LIB)/$(CMD)./:
	mkdir -p $@

clean purge:
	rm -fr lib/$(CMD)./json.bash $(CMD).* $(TMP) /tmp/$(CMD)-*

##
# Build rules:
lib/$(CMD)./json.bash: ext/JSON.sh/JSON.sh lib/$(CMD).
	cp $< $@
	chmod -x $@

$(CMD).txt: README.asc
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

ext/JSON.sh/JSON.sh ext/bash-tap/bash-tap:
	git submodule update --init
	@if [ ! -f "$@" ]; then \
	    echo "Failed to create '$@'"; \
	    exit 1; \
	fi

##
# Undocumented dev rules

# Install using symlinks so repo changes can be tested live
dev-install: build uninstall
	ln -s $$PWD/lib/$(CMD) $(GIT_INSTALL_LIB)/$(CMD)
	ln -s $$PWD/lib/$(CMD). $(GIT_INSTALL_LIB)/$(CMD).

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

