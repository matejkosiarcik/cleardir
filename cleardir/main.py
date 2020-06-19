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
import platform

log = logging.getLogger('main')


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

    mode_interactive = args.interactive
    mode_force = (args.force or args.interactive) and not args.dry_run

    if args.dry_run is args.force is args.interactive is False:
        print('Must pass either of --dry-run/--interactive/--force', file=sys.stderr)
        sys.exit(1)
    if args.dry_run is args.force is True:
        print('--dry-run/--force are mutually exclusive', file=sys.stderr)
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
    assert directories

    for directory in directories:
        process_directory(directory, mode_force, mode_interactive)
    return 0


# Process single directory
def process_directory(directory: str, is_real_delete: bool, is_interactive: bool):
    if not os.path.exists(directory):
        log.info('Could not find %s', directory)
        return
    log.info('Processing %s', directory)

    # TODO: replace check to darwin with check if dot_clean exists on path
    if os.path.isdir(os.path.realpath(directory)) and is_real_delete and platform.system() == 'Darwin':
        log.info('Precleaning ._* files')
        subprocess.check_call(['dot_clean', '-m', directory])

    def trydelete(file: str):
        if is_real_delete:
            try:
                delete(file)
            except FileNotFoundError:
                log.error('File %s not found', file)
        else:
            print('Would remove {}'.format(file))

    for file in find_files(directory):
        if is_interactive:
            user_input = input('Remove {}? [y|n]: '.format(file))
            print()
            while not user_input.lower() in ['y', 'n']:
                user_input = input('Not recognized. Remove {}? [y|n]: '.format(file))
                print()
            if user_input.lower() == 'y':
                trydelete(file)
        else:
            trydelete(file)

    log.info('Processed %s', directory)


# deletes file(or folder/symlink) from filesystem
def delete(file: str):
    print('Removing {}'.format(file))
    path = os.path.realpath(file)
    if os.path.isdir(path):
        shutil.rmtree(file)
    elif os.path.isfile(path):
        os.remove(file)
    else:
        raise FileNotFoundError('file {} not exists'.format(file))


def find_files(directory: str) -> Iterable[str]:
    # TODO: replace external `find` command with
    # https://stackoverflow.com/questions/19859840/excluding-directories-in-os-walk
    # https://docs.python.org/3/library/os.html
    # https://www.reddit.com/r/learnpython/comments/6yzgpm/osscandir_vs_oswalk_any_benefitdifference_of/

    depth_args = []
    if os.path.isdir(os.path.realpath(directory)):
        depth_args = ['-mindepth', '1']

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

        return ['find', directory] + depth_args + ['-not', '('] + ignored_all + [')', '-and', '('] + delete_all + [')']

    command = find_command()
    log.debug('Executing: %s', ' '.join(command))
    process = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in process.stdout:
        file = str(line.decode('utf-8').strip())
        yield file
    process.communicate()


if __name__ == "__main__":
    main(sys.argv[1:])
