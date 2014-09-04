# DO NOT EDIT.
#
# This Makefile came from Zilla::Dist. To upgrade it, run:
#
#   > make upgrade
#

.PHONY: cpan test

PERL ?= $(shell which perl)
ZILD := $(PERL) -S zild
LOG := $(PERL_ZILLA_DIST_RELEASE_LOG)

ifneq (,$(shell which zild))
    NAMEPATH := $(shell $(ZILD) meta =zild/libname)
    NAMEPATH := $(subst ::,/,$(NAMEPATH))
ifeq (,$(NAMEPATH))
    NAMEPATH := $(shell $(ZILD) meta name)
endif
    NAME := $(shell $(ZILD) meta name)
    VERSION := $(shell $(ZILD) meta version)
    RELEASE_BRANCH := $(shell $(ZILD) meta branch)
else
    NAME := No-Name
    NAMEPATH := $(NAME)
    VERSION := 0
    RELEASE_BRANCH := master
endif

DISTDIR := $(NAME)-$(VERSION)
DIST := $(DISTDIR).tar.gz
NAMEPATH := $(subst -,/,$(NAMEPATH))
SUCCESS := "$(DIST) Released!!!"

default: help

help:
	@echo ''
	@echo 'Makefile targets:'
	@echo ''
	@echo '    make test      - Run the repo tests'
	@echo '    make test-dev  - Run the developer only tests'
	@echo '    make test-all  - Run all tests'
	@echo '    make test-cpan - Make cpan/ dir and run tests in it'
	@echo '    make test-dist - Run the dist tests'
	@echo ''
	@echo '    make install   - Install the dist from this repo'
	@echo '    make prereqs   - Install the CPAN prereqs'
	@echo '    make update    - Update generated files'
	@echo '    make release   - Release the dist to CPAN'
	@echo ''
	@echo '    make cpan      - Make cpan/ dir with dist.ini'
	@echo '    make cpanshell - Open new shell into new cpan/'
	@echo ''
	@echo '    make dist      - Make CPAN distribution tarball'
	@echo '    make distdir   - Make CPAN distribution directory'
	@echo '    make distshell - Open new shell into new distdir'
	@echo ''
	@echo '    make upgrade   - Upgrade the build system (Makefile)'
	@echo '    make readme    - Make the ReadMe.pod file'
	@echo '    make travis    - Make a travis.yml file'
	@echo '    make uninstall - Uninstall the dist from this repo'
	@echo ''
	@echo '    make clean     - Clean up build files'
	@echo '    make help      - Show this help'
	@echo ''

#------------------------------------------------------------------------------
# Test Targets:
#------------------------------------------------------------------------------
test:
ifeq ($(wildcard pkg/no-test),)
ifneq ($(wildcard test),)
	$(PERL) -S prove -lv test
endif
else
	@echo "Testing not available. Use 'test-dist' instead."
endif

test-dev:
ifneq ($(wildcard test/devel),)
	$(PERL) -S prove -lv test/devel
endif

test-all: test test-dev

test-cpan cpantest: cpan
ifeq ($(wildcard pkg/no-test),)
	@echo '***** Running tests in `cpan/` directory'
	(cd cpan; $(PERL) -S prove -lv t) && make clean
else
	@echo "Testing not available. Use 'test-dist' instead."
endif

test-dist disttest: cpan
	@echo '***** Running tests in `$(DISTDIR)` directory'
	(cd cpan; dzil test) && make clean

#------------------------------------------------------------------------------
# Installation Targets:
#------------------------------------------------------------------------------
install: distdir
	@echo '***** Installing $(DISTDIR)'
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

prereqs:
	cpanm `$(ZILD) meta requires`

update: makefile
	@echo '***** Updating/regenerating repo content'
	make readme contrib travis version webhooks

#------------------------------------------------------------------------------
# Release and Build Targets:
#------------------------------------------------------------------------------
release:
ifneq ($(LOG),)
	@echo "$$(date) - Release $(DIST) STARTED" >> $(LOG)
endif
	make self-install
	make clean
	make update
	make check-release
	make date
	make test-all
	RELEASE_TESTING=1 make test-dist
	@echo '***** Releasing $(DISTDIR)'
	make dist
ifneq ($(PERL_ZILLA_DIST_RELEASE_TIME),)
	@echo $$(( ( $$PERL_ZILLA_DIST_RELEASE_TIME - $$(date +%s) ) / 60 )) \
	minutes, \
	$$(( ( $$PERL_ZILLA_DIST_RELEASE_TIME - $$(date +%s) ) % 60 )) \
	seconds, until RELEASE TIME!
	@echo sleep $$(( $$PERL_ZILLA_DIST_RELEASE_TIME - $$(date +%s) ))
	@sleep $$(( $$PERL_ZILLA_DIST_RELEASE_TIME - $$(date +%s) ))
endif
	cpan-upload $(DIST)
ifneq ($(LOG),)
	@echo "$$(date) - Release $(DIST) UPLOADED" >> $(LOG)
endif
	make clean
	[ -z "$$(git status -s)" ] || zild-git-commit
	git push
	git tag $(VERSION)
	git push --tag
	make clean
ifneq ($(PERL_ZILLA_DIST_AUTO_INSTALL),)
	@echo "***** Installing after release"
	make install
endif
	@echo
	git status
	@echo
	@[ -n "$$(which cowsay)" ] && cowsay "$(SUCCESS)" || echo "$(SUCCESS)"
	@echo
ifneq ($(LOG),)
	@echo "$$(date) - Release $(DIST) COMPLETED" >> $(LOG)
endif

cpan:
	@echo '***** Creating the `cpan/` directory'
	zild-make-cpan

cpanshell: cpan
	@echo '***** Starting new shell in `cpan/` directory'
	(cd cpan; $$SHELL)
	make clean

dist: clean cpan
	@echo '***** Creating new dist: $(DIST)'
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	rm -fr cpan

distdir: clean cpan
	@echo '***** Creating new dist directory: $(DISTDIR)'
	(cd cpan; dzil build)
	mv cpan/$(DIST) .
	tar xzf $(DIST)
	rm -fr cpan $(DIST)

distshell: distdir
	@echo '***** Starting new shell in `$(DISTDIR)` directory'
	(cd $(DISTDIR); $$SHELL)
	make clean

upgrade:
	@echo '***** Checking that Zilla-Dist Makefile is up to date'
	cp `$(ZILD) sharedir`/Makefile ./

readme:
	swim --pod-cpan doc/$(NAMEPATH).swim > ReadMe.pod

contrib:
	$(PERL) -S zild-render-template Contributing

travis:
	$(PERL) -S zild-render-template travis.yml .travis.yml

uninstall: distdir
	(cd $(DISTDIR); perl Makefile.PL; make uninstall)
	make clean

clean purge:
	rm -fr cpan .build $(DIST) $(DISTDIR)

#------------------------------------------------------------------------------
# Non-pulic-facing targets:
#------------------------------------------------------------------------------
check-release:
	@echo '***** Checking readiness to release $(DIST)'
	RELEASE_BRANCH=$(RELEASE_BRANCH) zild-check-release
	git stash
	rm -fr .git/rebase-apply
	git pull --rebase origin $(RELEASE_BRANCH)
	git stash pop

# We don't want to update the Makefile in Zilla::Dist since it is the real
# source, and would be reverting to whatever was installed.
ifeq (Zilla-Dist,$(NAME))
makefile:
	@echo Skip 'make upgrade'

self-install: install
	[ -n "which plenv" ] && plenv rehash
else
makefile:
	@cp Makefile /tmp/
	make upgrade
	@if [ -n "`diff Makefile /tmp/Makefile`" ]; then \
	    echo "ATTENTION: Dist-Zilla Makefile updated. Please re-run the command."; \
	    exit 1; \
	fi
	@rm /tmp/Makefile

self-install:
endif

date:
	$(ZILD) changes date "`date`"

version:
	$(PERL) -S zild-version-update

webhooks:
	$(PERL) -S zild webhooks
