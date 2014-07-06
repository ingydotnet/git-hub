NAME = git-hub-travis
LIB = lib
LIBS = $(shell find $(LIB) -type f) \
	$(shell find $(LIB) -type l)
DOC = doc/$(NAME).swim
MAN = $(MAN1)/$(NAME).1
MAN1 = man/man1

# XXX Make these vars look like git.git/Makefile style
PREFIX ?= /usr/local
INSTALL_LIB ?= $(shell git --exec-path)/git-hub.d
INSTALL_MAN ?= $(PREFIX)/share/man/man1

##
# User targets:
default: help

help:
	@echo 'Makefile targets:'
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
	prove $(PROVE_OPTIONS) test/

install: install-lib install-doc

install-lib: $(INSTALL_LIB)
	install -C -d -m 0755 $(INSTALL_LIB)/
	install -C -m 0755 $(LIBS) $(INSTALL_LIB)/

install-doc:
	install -C -d -m 0755 $(INSTALL_MAN)
	install -C -m 0644 doc/$(NAME).1 $(INSTALL_MAN)

uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -fr $(INSTALL_LIB)

uninstall-doc:
	rm -f $(INSTALL_MAN)/$(NAME).1

##
# Build rules:
doc: $(MAN) ReadMe.pod

$(MAN1)/%.1: doc/%.swim swim-check
	swim --to=man $< > $@

ReadMe.pod: $(DOC) swim-check
	swim --to=pod --complete=1 --wrap=1 $< > $@

swim-check:
	@# Need to assert Swim and Swim::Plugin::badge are installed
