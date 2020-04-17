#!/usr/bin/env python
# TODO: apply formatting and linting

from __future__ import (
    absolute_import, division, print_function, unicode_literals
)
from builtins import *
import argparse
import sys
import os
import subprocess
import shutil
import functools
from typing import List, Iterable
import logging
import itertools
import enum

log = logging.getLogger('main')

class Mode(enum.Enum):
    DRY_RUN = 0,
    FORCE = 1,
    INTERACTIVE = 2

# Main function
def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--dry-run', action='store_true',
                        help='do not remove files, only print what would be deleted')
    parser.add_argument('-f', '--force', action='store_true',
                        help='actually perform file/directory removal')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='additional logging output')
    parser.add_argument('paths', nargs='*', help='directories to clear (also accepts filepaths)')
    parser.prog = 'cleardir'
    # TODO: add -i/--interactive flag (similar to `git clean -i`)
    # TODO: add -q/--quiet flag
    # TODO: add -V/--version flag (probably after first deployment)
    args = parser.parse_args(argv)

    # if args.verbose and args.quiet:
    #     print('Can\'t accept both "quiet" and "verbose" flags.', file=sys.stderr)
    #     return 1

    mode = None
    if args.dry_run:
        mode = Mode.DRY_RUN
    elif args.force:
        mode = Mode.FORCE

    if mode is None:
        print('Must pass either --force or --dry-run', file=sys.stderr)
        sys.exit(1)

    if sum(1 if x else 0 for x in [args.dry_run, args.force]) > 1:
        print('--force and --dry-run are mutually exclusive', file=sys.stderr)
        sys.exit(1)

    # setup logging
    log.setLevel(logging.WARN)
    if args.verbose:
        log.setLevel(logging.DEBUG)
    log.addHandler(logging.StreamHandler())  # stderr

    directories = args.paths
    if directories is None:
        log.info('No directory given. Using "."')
        directories = ['.']
    directories = [x for x in directories if len(x) > 0]
    assert len(directories) > 0

    for directory in directories:
        process_directory(directory, mode)
    return 0


# Process single directory
def process_directory(directory: str, mode: Mode):
    if not os.path.exists(directory):
        log.info('Could not find %s' % directory)
        return
    log.info('Processing %s' % directory)

    if os.path.isdir(os.path.realpath(directory)):
        # TODO: call dot_clean if not dry_run
        pass

    for file in find_files(directory):
        if mode == Mode.DRY_RUN:
            print('Would remove %s' % file)
        elif mode == Mode.FORCE:
            print('Removing %s' % file)
            try:
                delete(file)
            except FileNotFoundError:
                pass
        elif mode == Mode.INTERACTIVE:
            raise NotImplementedError('Interactive mode not yet implemented')

    log.info('Processed %s' % directory)


# deletes file(or folder/symlink) from filesystem
def delete(entry: str):
    path = os.path.realpath(entry)
    if os.path.isdir(path):
        shutil.rmtree(entry)
    elif os.path.isfile(path):
        os.remove(entry)
    else:
        raise FileNotFoundError('file "%s" not exists' % entry)


def find_files(dir: str) -> Iterable[str]:
    def find_command() -> Iterable[str]:
        # returns generic list of files to add to "find" command
        delete_files = [
            '.DS_Store',  # macOS
            '.AppleDouble',  # macOS
            '.LSOverride',  # macOS
            '.localized',  # macOS
            'CMakeCache.txt',  # cmake
            '._*',  # dotbar macos/BSD files
            '[T|t]humbs.db',  # Windows
            'ehthumbs.db',  # Windows
            'ehthumbs_vista.db',  # Windows
            '[D|d]esktop.ini',  # Windows
        ]
        delete_files2 = (['-name', x, '-type', 'f'] for x in delete_files)
        delete_folders = [
            'dist',  # default dist folder
            'node_modules',  # npm, yarn
            'bower_components',  # bower
            'build',  # generic build folder
            '.build',  # swift package manager
            'Pods',  # cocoapods (obj-c, swift)
            'Carthage',  # carthage (obj-c, swift)
            'CMakeFiles',  # cmake
            'CMakeScripts',  # cmake
            'venv',  # python (virtualenv, pyenv)
            '.venv',  # python (virtualenv, pyenv)
        ]
        # TODO: consider .Trash, .Trashes, .Trash-*
        delete_folders2 = (['-name', x, '-type', 'd', '-prune'] for x in delete_folders)
        delete_all = functools.reduce(lambda all, el: all + ['-or'] + el, itertools.chain(delete_folders2, delete_files2))

        ignored_folders = [
            '.git',
            '.hg',
            '.svn',
        ]
        ignored_folders2 = (['-path', "*/%s/*" % x, '-prune'] for x in ignored_folders)
        ignored_all = functools.reduce(lambda all, el: all + ['-or'] + el, ignored_folders2)

        return ['find', dir, '-not', '('] + ignored_all + [')', '-and', '('] + delete_all + [')']

    command = find_command()
    log.debug('Executing: %s' % ' '.join(command))
    process = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in process.stdout:
        file = str(line.decode('utf-8').strip())
        yield file
    process.communicate()


if __name__ == "__main__":
    main(sys.argv[1:])
