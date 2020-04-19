# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables
DESTDIR ?= "$${HOME}/.bin"
SHELL := /bin/sh
.SHELLFLAGS := -ec

.DEFAULT: all
.PHONY: all
all: bootstrap lint build test

.PHONY: bootstrap
bootstrap:
	if [ "$$(uname -s)" = Darwin ] && command -v brew >/dev/null 2>&1; then \
		brew bundle \
	;fi
	# check if virtual environment exists or create it
	[ -n "$${VIRTUAL_ENV+x}" ] || [ -d venv ] \
		|| python3 -m venv venv \
		|| python -m venv venv \
		|| virtualenv venv \
		|| mkvirtualenv venv
	# install dependencies into existing or created virtual environment
	if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
		pip install --upgrade pip setuptools \
		&& pip install --requirement requirements.txt --requirement requirements-dev.txt \
	;else exit 1; fi
	npm install --prefix tests-cli

.PHONY: lint
lint:
	# TODO: remove this after it is implemented in-module for python2
	# crude check that strip-hints work
	if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
		strip-hints --to-empty src/main.py >/dev/null \
	;else exit 1; fi
	# TODO: lint tasks

.PHONY: build
build:
	rm -rf dist
	if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
		PYTHONOPTIMIZE=2 pyinstaller src/main.py --onefile --noconfirm --clean \
	;else exit 1; fi
	mv dist/main dist/cleardir

.PHONY: test
test: src-test build-test install-test
	# test that tests fail when no source
	! (npm run --prefix tests-cli test >/dev/null 2>&1)
	! (TEST_COMMAND= npm run --prefix tests-cli test >/dev/null 2>&1)
	! (TEST_COMMAND=placeholder npm run --prefix tests-cli test >/dev/null 2>&1)

.PHONY: src-test
src-test:
	# main tests
	if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
		TEST_COMMAND="python src/main.py" npm run --prefix tests-cli test \
	;else exit 1; fi
	# TODO: test for python2
	# TODO: test for python3 module

.PHONY: build-test
build-test:
	TEST_COMMAND="./dist/cleardir" npm run --prefix tests-cli test

.PHONY: install-test
install-test:
	# TODO: tests for installed executable via setup.py/pip
	# if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
	# 	pip uninstall cleardir \
	# 	&& pip install . \
	# 	&& TEST_COMMAND="$${VIRTUAL_ENV}/bin/cleardir" npm run --prefix tests-cli test \
	# ;else exit 1; fi

.PHONY: system-test
system-test:
	command -v cleardir
	TEST_COMMAND="cleardir" npm run --prefix tests-cli test

.PHONY: install
install:
	# TODO: replace with setup.py
	rm -f "$(DESTDIR)/cleardir"
	cp "$(CURDIR)/src/main.py" "$(DESTDIR)/cleardir"
	chmod +x "$(DESTDIR)/cleardir"
