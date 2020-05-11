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
from typing import List, Iterable, Optional
import logging
import itertools
import enum

log = logging.getLogger('main')

class Mode(enum.Enum):
    DRY_RUN = 0,
    FORCE = 1,
    INTERACTIVE = 2

# Main function
def main(argv: Optional[List[str]]) -> int:
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--dry-run', action='store_true',
                        help='do not remove files, only print what would be deleted')
    parser.add_argument('-f', '--force', action='store_true',
                        help='force remove all matching files')
    parser.add_argument('-i', '--interactive', action='store_true',
                        help='work in interactive mode (ask user for each file whether to remove it or not)')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='additional logging output')
    parser.add_argument('paths', nargs='*', help='directories to clear (also accepts filepaths)')
    parser.prog = 'cleardir'
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
    elif args.interactive:
        mode = Mode.INTERACTIVE

    if mode is None:
        print('Must pass either of --dry-run/--interactive/--force', file=sys.stderr)
        sys.exit(1)

    if sum(1 if x else 0 for x in [args.dry_run, args.force, args.interactive]) > 1:
        print('--dry-run/--interactive/--force are mutually exclusive', file=sys.stderr)
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
            try:
                delete(file)
            except FileNotFoundError:
                pass
        elif mode == Mode.INTERACTIVE:
            user_input = input('Remove %s? [y|n]: ' % file)
            while not user_input.lower() in ['y', 'n']:
                user_input = input('Not recognized. Remove %s? [y|n]: ' % file)
            if user_input.lower() == 'y':
                try:
                    delete(file)
                except FileNotFoundError:
                    pass

    log.info('Processed %s' % directory)


# deletes file(or folder/symlink) from filesystem
def delete(file: str):
    print('Removing %s' % file)
    path = os.path.realpath(file)
    if os.path.isdir(path):
        shutil.rmtree(file)
    elif os.path.isfile(path):
        os.remove(file)
    else:
        raise FileNotFoundError('file "%s" not exists' % file)


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
