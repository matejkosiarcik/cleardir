# This Makefile does not contain any build steps
# It only groups scripts to use in project

MAKEFLAGS += --warn-undefined-variables
DESTDIR ?= "$${HOME}/.bin"

.DEFAULT: all
.PHONY: all
all: bootstrap lint test

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
		&& pip3 install --requirement requirements-dev.txt \
	;else exit 1; fi
	npm install --prefix tests-cli

.PHONY: lint
lint:
	# TODO: lint tasks

.PHONY: test
test:
	! npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND= npm run --prefix tests-cli test >/dev/null 2>&1
	! TEST_COMMAND=placeholder npm run --prefix tests-cli test >/dev/null 2>&1
	TEST_COMMAND="python3 src/main.py" npm run --prefix tests-cli test

	# TODO: tests for installed executable
	# if [ -n "$${VIRTUAL_ENV+x}" ] || . venv/bin/activate; then \
	# 	pip3 uninstall cleardir \
	# 	&& pip3 install . \
	# 	&& TEST_COMMAND="$${VIRTUAL_ENV}/bin/cleardir" npm run --prefix tests-cli test
	# ;else exit 1; fi

.PHONY: install
install:
	# TODO: replace with setup.py
	rm -f "$(DESTDIR)/cleardir"
	cp "$(CURDIR)/src/main.py" "$(DESTDIR)/cleardir"
	chmod +x "$(DESTDIR)/cleardir"
