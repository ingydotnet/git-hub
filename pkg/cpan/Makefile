# DO NOT EDIT.
#
# This Makefile came from Zilla::Dist. To upgrade it, run:
#
#   > make upgrade
#

.PHONY: cpan test

PERL ?= $(shell which perl)
ZILD := $(PERL) -S zild

ifneq (,$(shell which zild))
    NAMEPATH := $(shell $(ZILD) meta =cpan/libname)
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
	@echo '    make install   - Install the dist from this repo'
	@echo '    make prereqs   - Install the CPAN prereqs'
	@echo '    make update    - Update generated files'
	@echo '    make release   - Release the dist to CPAN'
	@echo ''
	@echo '    make cpan      - Make cpan/ dir with dist.ini'
	@echo '    make cpanshell - Open new shell into new cpan/'
	@echo '    make cpantest  - Make cpan/ dir and run tests in it'
	@echo ''
	@echo '    make dist      - Make CPAN distribution tarball'
	@echo '    make distdir   - Make CPAN distribution directory'
	@echo '    make distshell - Open new shell into new distdir'
	@echo '    make disttest  - Run the dist tests'
	@echo ''
	@echo '    make upgrade   - Upgrade the build system (Makefile)'
	@echo '    make readme    - Make the ReadMe.pod file'
	@echo '    make travis    - Make a travis.yml file'
	@echo ''
	@echo '    make clean     - Clean up build files'
	@echo '    make help      - Show this help'
	@echo ''

test:
ifeq ($(wildcard pkg/no-test),)
	$(PERL) -S prove -lv test
else
	@echo "Testing not available. Use 'disttest' instead."
endif

install: distdir
	@echo '***** Installing $(DISTDIR)'
	(cd $(DISTDIR); perl Makefile.PL; make install)
	make clean

prereqs:
	cpanm `$(ZILD) meta requires`

update: makefile
	@echo '***** Updating/regenerating repo content'
	make readme contrib travis version webhooks

release: clean update check-release date test disttest
	@echo '***** Releasing $(DISTDIR)'
	make dist
	cpan-upload $(DIST)
	make clean
	[ -z "$$(git status -s)" ] || git commit -am '$(VERSION)'
	git push
	git tag $(VERSION)
	git push --tag
	make clean
	git status
	@echo
	@[ -n "$$(which cowsay)" ] && cowsay "$(SUCCESS)" || echo "$(SUCCESS)"
	@echo

cpan:
	@echo '***** Creating the `cpan/` directory'
	zild-make-cpan

cpanshell: cpan
	@echo '***** Starting new shell in `cpan/` directory'
	(cd cpan; $$SHELL)
	make clean

cpantest: cpan
ifeq ($(wildcard pkg/no-test),)
	@echo '***** Running tests in `cpan/` directory'
	(cd cpan; $(PERL) -S prove -lv t) && make clean
else
	@echo "Testing not available. Use 'disttest' instead."
endif

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

disttest: cpan
	@echo '***** Running tests in `$(DISTDIR)` directory'
	(cd cpan; dzil test) && make clean

upgrade:
	@echo '***** Checking that Zilla-Dist Makefile is up to date'
	cp `$(ZILD) sharedir`/Makefile ./

readme:
	swim --pod-cpan doc/$(NAMEPATH).swim > ReadMe.pod

contrib:
	$(PERL) -S zild-render-template Contributing

travis:
	$(PERL) -S zild-render-template travis.yml .travis.yml

clean purge:
	rm -fr cpan .build $(DIST) $(DISTDIR)

#------------------------------------------------------------------------------
# Non-pulic-facing targets:
#------------------------------------------------------------------------------
check-release:
	@echo '***** Checking readiness to release $(DIST)'
	RELEASE_BRANCH=$(RELEASE_BRANCH) zild-check-release
	git stash
	git pull --rebase origin $(RELEASE_BRANCH)
	git stash pop

# We don't want to update the Makefile in Zilla::Dist since it is the real
# source, and would be reverting to whatever was installed.
ifeq (Zilla-Dist,$(NAME))
makefile:
	@echo Skip 'make upgrade'
else
makefile:
	@cp Makefile /tmp/
	make upgrade
	@if [ -n "`diff Makefile /tmp/Makefile`" ]; then \
	    echo "ATTENTION: Dist-Zilla Makefile updated. Please re-run the command."; \
	    exit 1; \
	fi
	@rm /tmp/Makefile
endif

date:
	$(ZILD) changes date "`date`"

version:
	$(PERL) -S zild-version-update

webhooks:
	$(PERL) -S zild webhooks
