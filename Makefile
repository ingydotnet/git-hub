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

build: git-hub

test: build
	@# prove -e bash test
	bash test/repos-create.t

install: build uninstall
	cp ./$(CMD) $(GIT_INSTALL_LIB)/

uninstall:
	rm -f $(GIT_INSTALL_LIB)/$(CMD)

clean purge:
	rm -fr ./$(CMD) $(TMP)

##
# Build rules:
git-hub: src/git-hub.bash
	cp $< ./$@
	chmod +x $@

##
# Undocumented dev rules
install-link: build uninstall
	ln -s $(PWD)/$(CMD) $(GIT_INSTALL_LIB)/$(CMD)
