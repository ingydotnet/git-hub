# Make sure we have 'git' and it works OK:
ifeq ($(shell which git),)
    $(error 'git' is not installed on this system)
endif
GITVER ?= $(word 3,$(shell git --version))

NAME = git-hub
LIB = lib
LIBS = $(shell find $(LIB) -type f) \
	$(shell find $(LIB) -type l)
DOC = doc/$(NAME).swim
MAN = $(MAN1)/$(NAME).1
MAN1 = man/man1
EXT = $(LIB)/$(NAME).d
EXTS = $(shell find $(EXT) -type f) \
	$(shell find $(EXT) -type l)
SHARE = share

# XXX Make these vars look like git.git/Makefile style
PREFIX ?= /usr/local
# XXX Using sed for now. Would like to use bash or make syntax.
# If GIT_EXEC_PATH is set, `git --exec-path` will contain that appended to the
# front. We just want the path where git is actually installed:
INSTALL_LIB ?= $(shell git --exec-path | sed 's/.*://')
INSTALL_CMD ?= $(INSTALL_LIB)/$(NAME)
INSTALL_EXT ?= $(INSTALL_LIB)/$(NAME).d
INSTALL_MAN1 ?= $(PREFIX)/share/man/man1

##
# User targets:
default: help

help:
	@echo 'Makefile rules:'
	@echo ''
	@echo 'test       Run all tests'
	@echo 'install    Install $(NAME)'
	@echo 'uninstall  Uninstall $(NAME)'

.PHONY: test
test:
ifeq ($(shell which prove),)
	@echo '`make test` requires the `prove` utility'
	@exit 1
endif
	prove $(PROVEOPT:%=% )test/

install: install-lib install-doc

install-lib: $(DESTDIR)$(INSTALL_EXT)
	install -C -m 0755 $(LIBS) $(DESTDIR)$(INSTALL_LIB)/
	install -d -m 0755 $(DESTDIR)$(INSTALL_EXT)/
	install -C -m 0755 $(EXTS) $(DESTDIR)$(INSTALL_EXT)/

install-doc:
	install -d -m 0755 $(DESTDIR)$(INSTALL_MAN1)
	install -C -m 0644 $(MAN) $(DESTDIR)$(INSTALL_MAN1)

uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -f $(DESTDIR)$(INSTALL_CMD)
	rm -fr $(DESTDIR)$(INSTALL_EXT)

uninstall-doc:
	rm -f $(DESTDIR)$(INSTALL_MAN1)/$(NAME).1

$(DESTDIR)$(INSTALL_EXT):
	mkdir -p $@

clean purge:
	git clean -fxd

##
# Build rules:

update: doc compgen

doc: $(MAN) ReadMe.pod
	perl tool/generate-help-functions.pl $(DOC) > \
	    $(EXT)/help-functions.bash

compgen:
	perl tool/generate-completion.pl bash $(DOC) $(LIB)/git-hub > \
	    $(SHARE)/completion.bash
	perl tool/generate-completion.pl zsh $(DOC) $(LIB)/git-hub > \
	    $(SHARE)/zsh-completion/_git-hub

$(MAN1)/%.1: doc/%.swim swim-check
	swim --to=man $< > $@

ReadMe.pod: $(DOC) swim-check
	swim --to=pod --complete --wrap $< > $@

swim-check:
	@# Need to assert Swim and Swim::Plugin::badge are installed

#------------------------------------------------------------------------------
# BPAN Rules
#------------------------------------------------------------------------------
BPAN_INSTALL_LIB=$(shell bpan env BPAN_LIB)
BPAN_INSTALL_EXT ?= $(BPAN_INSTALL_LIB)/$(NAME).d
BPAN_INSTALL_MAN1=$(shell bpan env BPAN_MAN1)

bpan-install:
	install -C -m 0755 $(LIB) $(BPAN_INSTALL_LIB)/
	install -d -m 0755 $(BPAN_INSTALL_EXT)/
	install -C -m 0755 $(EXTS) $(BPAN_INSTALL_EXT)/
	install -d -m 0755 $(BPAN_INSTALL_MAN1)
	install -C -m 0644 $(MAN) $(BPAN_INSTALL_MAN1)
