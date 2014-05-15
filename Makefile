export PATH := ../kwim-pm/bin:$(PATH)

CMD := git-hub

LOCAL_LIB := $(shell pwd)/lib/$(CMD)
LOCAL_MAN := $(shell pwd)/man
LOCAL_MAN1 := $(LOCAL_MAN)/man1
LOCAL_EXT = $(LOCAL_LIB).d
LOCAL_EXTS = $(shell find $(LOCAL_EXT) -type f) \
	    $(shell find $(LOCAL_EXT) -type l)

# XXX Make these vars look like git.git/Makefile style
PREFIX ?= /usr/local

# XXX Using sed for now. Would like to use bash or make syntax.
# If GIT_EXEC_PATH is set, `git --exec-path` will contain that appended to the
# front. We just want the path where git is actually installed:
INSTALL_LIB ?= $(shell git --exec-path | sed 's/.*://')
INSTALL_CMD ?= $(INSTALL_LIB)/$(CMD)
INSTALL_EXT ?= $(INSTALL_LIB)/$(CMD).d
INSTALL_MAN ?= $(PREFIX)/share/man/man1

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

test:
ifeq ($(shell which prove),)
	@echo '`make test` requires the `prove` utility'
	@exit 1
endif
	prove $(PROVEOPT:%=% )test/

.PHONY: install install-lib install-doc
install: install-lib install-doc

install-lib: $(INSTALL_EXT)
	install -C -m 0755 $(LOCAL_LIB) $(INSTALL_LIB)/
	install -C -d -m 0755 $(INSTALL_EXT)/
	install -C -m 0755 $(LOCAL_EXTS) $(INSTALL_EXT)/

install-doc:
	install -C -d -m 0755 $(INSTALL_MAN)
	install -C -m 0644 $(LOCAL_MAN1)/$(CMD).1 $(INSTALL_MAN)

.PHONY: uninstall uninstall-lib uninstall-doc
uninstall: uninstall-lib uninstall-doc

uninstall-lib:
	rm -f $(INSTALL_CMD)
	rm -fr $(INSTALL_EXT)

uninstall-doc:
	rm -f $(INSTALL_MAN)/$(CMD).1

$(INSTALL_EXT):
	mkdir -p $@

##
# Build rules:
.PHONY: doc
doc: $(LOCAL_MAN1)/$(CMD).1 doc/$(CMD).kwim
	perl tool/generate-help-functions.pl doc/$(CMD).kwim > \
	    $(LOCAL_EXT)/help-functions.bash

$(LOCAL_MAN1)/$(CMD).1: $(CMD).1
	mv $< $@

%.1: %.pod
	pod2man --utf8 $< > $@

%.pod: doc/%.kwim
	kwim --to=pod --wrap=1 --complete=1 $< > $@
	cp $@ ReadMe.pod

#------------------------------------------------------------------------------
# BPAN Rules
#------------------------------------------------------------------------------
BPAN_INSTALL_LIB=$(shell bpan env BPAN_LIB)
BPAN_INSTALL_EXT ?= $(BPAN_INSTALL_LIB)/$(CMD).d
BPAN_INSTALL_MAN1=$(shell bpan env BPAN_MAN1)

bpan-install:
	install -C -m 0755 $(LOCAL_LIB) $(BPAN_INSTALL_LIB)/
	install -C -d -m 0755 $(BPAN_INSTALL_EXT)/
	install -C -m 0755 $(LOCAL_EXTS) $(BPAN_INSTALL_EXT)/
	install -C -d -m 0755 $(BPAN_INSTALL_MAN1)
	install -C -m 0644 $(LOCAL_MAN1)/$(CMD).1 $(BPAN_INSTALL_MAN1)
