.PHONY: test install

GIT_INSTALL_LIB ?= $(shell git --exec-path)

default: help

help:
	@echo 'Makefile rules:'
	@echo ''
	@echo 'test       Run all tests'
	@echo 'install    Install git-hub'
	@echo 'uninstall  Uninstall git-hub'

test:
	# prove -e bash test
	PATH=$(PWD)/test:$(PATH) \
	bash test/new-repo.t

install:
	cp ./git-hub.sh $(GIT_INSTALL_LIB)/git-hub

uninstall:
	rm $(GIT_INSTALL_LIB)/git-hub

clean purge:
	rm -fr ./tmp/
