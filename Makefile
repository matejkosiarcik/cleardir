# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables
DESTDIR ?= "$${HOME}/.bin"

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
		pip3 install --upgrade pip setuptools \
		&& pip3 install --requirement requirements.txt --requirement requirements-dev.txt \
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
	if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
		cython src/main.py --embed -3 --output-file src/main.c \
	;else exit 1; fi
	# Below command works on my current macOS system, clean up before adapting
	# clang src/main.c -o cleardir -Os -I /usr/local/Cellar/python@3.8/3.8.2/Frameworks/Python.framework/Versions/3.8/include/python3.8 -L/usr/local/Cellar/python@3.8/3.8.2/Frameworks/Python.framework/Versions/3.8/lib -lpython3.8 -lpthread -lm -lutil -ldl

.PHONY: test
test:
	! npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND= npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND=placeholder npm run --prefix tests-cli test >/dev/null 2>&1

	TEST_COMMAND="python3 src/main.py" npm run --prefix tests-cli test
	# TODO: test for python2
	# TODO: test for python3 module

	# TODO: test for cython executable
	# TEST_COMMAND="./cleardir" npm run --prefix tests-cli test

	# TODO: tests for installed executable
	# if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
	# 	pip3 uninstall cleardir \
	# 	&& pip3 install . \
	# 	&& TEST_COMMAND="$${VIRTUAL_ENV}/bin/cleardir" npm run --prefix tests-cli test \
	# ;else exit 1; fi

.PHONY: install
install:
	# TODO: replace with setup.py
	rm -f "$(DESTDIR)/cleardir"
	cp "$(CURDIR)/src/main.py" "$(DESTDIR)/cleardir"
	chmod +x "$(DESTDIR)/cleardir"
