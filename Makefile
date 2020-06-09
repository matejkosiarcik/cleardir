# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables
DESTDIR ?= "$${HOME}/.bin"
SHELL := /bin/sh
.SHELLFLAGS := -ec
ACTIVATE_VENV := [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate

.DEFAULT: all
.PHONY: all
all: bootstrap lint test build build-test

.PHONY: unit
unit: bootstrap lint test

.PHONY: bootstrap
bootstrap:
	# check if virtual environment exists or create it
	[ -n "$${VIRTUAL_ENV+x}" ] || [ -d venv ] \
		|| python3 -m venv venv \
		|| python -m venv venv \
		|| virtualenv venv \
		|| mkvirtualenv venv
	# install dependencies into existing or created virtual environment
	if $(ACTIVATE_VENV); then \
		python -m pip install --upgrade pip setuptools wheel && \
		python -m pip install --requirement requirements-dev.txt \
	;else exit 1; fi
	npm install --prefix tests-cli

.PHONY: lint
lint:
	if $(ACTIVATE_VENV); then \
		pylint cleardir/main.py && \
		pycodestyle cleardir/main.py \
	;else exit 1; fi

.PHONY: build
build:
	rm -rf dist
	if $(ACTIVATE_VENV); then \
		PYTHONOPTIMIZE=2 pyinstaller cleardir/main.py --onefile --noconfirm --clean \
	;else exit 1; fi
	mv dist/main dist/cleardir

.PHONY: test
test: src-test install-test

.PHONY: src-test
src-test:
	# test that tests fail when no source
	! (npm test --prefix tests-cli >/dev/null 2>&1)
	! (TEST_COMMAND= npm test --prefix tests-cli >/dev/null 2>&1)
	! (TEST_COMMAND=placeholder npm test --prefix tests-cli >/dev/null 2>&1)

	# main tests
	if $(ACTIVATE_VENV); then \
		TEST_COMMAND="python cleardir/main.py" npm test --prefix tests-cli \
	;else exit 1; fi
	# TODO: test for python2
	# TODO: test for python3 module

.PHONY: install-test
install-test:
	# TODO: tests for installed executable via setup.py/pip
	# if $(ACTIVATE_VENV); then \
	# 	python -m pip uninstall cleardir \
	# 	&& python -m pip install . \
	# 	&& TEST_COMMAND="$${VIRTUAL_ENV}/bin/cleardir" npm test --prefix tests-cli \
	# ;else exit 1; fi

.PHONY: build-test
build-test:
	TEST_COMMAND="./dist/cleardir" npm test --prefix tests-cli

.PHONY: system-test
system-test:
	command -v cleardir
	TEST_COMMAND="cleardir" npm test --prefix tests-cli

.PHONY: install
install:
	printf 'Prefer installing with pip! Only for development.\n'
	rm -rf "$(DESTDIR)/cleardir"
	cp "$(CURDIR)/cleardir/main.py" "$(DESTDIR)/cleardir"
	chmod +x "$(DESTDIR)/cleardir"
