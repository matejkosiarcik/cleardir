# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables
DESTDIR ?= "$${HOME}/.bin"
CC ?= cc

.DEFAULT: all
.PHONY: all
all: bootstrap lint build test

.PHONY: bootstrap
bootstrap:
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
test:
	# test that tests fail with no source
	! npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND= npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND=placeholder npm run --prefix tests-cli test >/dev/null 2>&1

	# main tests
	TEST_COMMAND="python3 src/main.py" npm run --prefix tests-cli test
	# TODO: test for python2
	# TODO: test for python3 module

	# test compiled executables
	if [ -d dist ]; then \
		TEST_COMMAND="./dist/cleardir" npm run --prefix tests-cli test \
	;fi

	# TODO: tests for installed executable via setup.py/pip
	# if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
	# 	pip uninstall cleardir \
	# 	&& pip install . \
	# 	&& TEST_COMMAND="$${VIRTUAL_ENV}/bin/cleardir" npm run --prefix tests-cli test \
	# ;else exit 1; fi

.PHONY: install
install:
	# TODO: replace with setup.py
	rm -f "$(DESTDIR)/cleardir"
	cp "$(CURDIR)/src/main.py" "$(DESTDIR)/cleardir"
	chmod +x "$(DESTDIR)/cleardir"
