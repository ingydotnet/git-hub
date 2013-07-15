.PHONY: default help build test install

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

build: git-hub lib/core.bash lib/json.bash

test: build
	@# prove -e bash test
	bash test/repos-create.t

install: build uninstall $(GIT_INSTALL_LIB)/lib/
	cp $(CMD) $(GIT_INSTALL_LIB)/
	cp lib/core.bash $(GIT_INSTALL_LIB)/lib/core.bash
	cp lib/json.bash $(GIT_INSTALL_LIB)/lib/json.bash

uninstall:
	rm -f $(GIT_INSTALL_LIB)/$(CMD)
	rm -f $(GIT_INSTALL_LIB)/lib/core.bash
	rm -f $(GIT_INSTALL_LIB)/lib/json.bash

$(GIT_INSTALL_LIB)/lib/:
	mkdir -p $@

clean purge:
	rm -fr $(CMD) lib $(TMP) /tmp/git-hub-*

##
# Build rules:
git-hub: src/git-hub.bash
	cp $< $@
	chmod +x $@

lib/core.bash: src/core.bash lib
	cp $< $@

lib/json.bash: ext/JSON.sh/JSON.sh lib
	cp $< $@
	chmod -x $@

lib:
	mkdir $@

ext/JSON.sh/JSON.sh:
	git submodule update --init
	if [ ! -f "$@" ]; then \
	    echo "Failed to create '$@'"; \
	    exit 1; \
	fi

##
# Undocumented dev rules
install-link: build uninstall $(GIT_INSTALL_LIB)/lib/
	ln -s $$PWD/$(CMD) $(GIT_INSTALL_LIB)/$(CMD)
	ln -s $$PWD/lib/core.bash $(GIT_INSTALL_LIB)/lib/core.bash
	ln -s $$PWD/lib/json.bash $(GIT_INSTALL_LIB)/lib/json.bash
