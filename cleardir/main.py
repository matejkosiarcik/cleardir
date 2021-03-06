#!/usr/bin/env python3
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
from typing import List, Iterable, Optional
import logging

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
    parser.add_argument('paths', nargs='*', default=['.'],
                        help='directories to clear (also accepts filepaths)')
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
        return 1
    if args.dry_run is args.force is True:
        print('--dry-run/--force are mutually exclusive', file=sys.stderr)
        return 1

    # setup logging
    log.setLevel(logging.WARN)
    if args.verbose:
        log.setLevel(logging.DEBUG)
    log.addHandler(logging.StreamHandler())  # stderr

    directories = args.paths
    directories = [os.path.realpath(x) for x in directories if len(x) > 0]
    if not directories:
        print('No directories given', file=sys.stderr)
        return 1

    for directory in directories:
        process_directory(directory, mode_force, mode_interactive)
    return 0


# Process single directory
def process_directory(directory: str, is_real_delete: bool, is_interactive: bool):
    if not os.path.exists(directory):
        log.info('Could not find %s', directory)
        return
    log.info('Processing %s', directory)

    if os.path.isdir(directory) and is_real_delete and shutil.which('dot_clean'):
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
            while not user_input.lower() in ['y', 'n']:
                user_input = input('Not recognized. Remove {}? [y|n]: '.format(file))
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
    delete_files = {
        '.DS_Store',  # macOS
        '.AppleDouble',  # macOS
        '.LSOverride',  # macOS
        '.localized',  # macOS
        'CMakeCache.txt',  # cmake
        'Thumbs.db',  # Windows
        'thumbs.db',  # Windows
        'ehthumbs.db',  # Windows
        'ehthumbs_vista.db',  # Windows
        'desktop.ini',  # Windows
        'Desktop.ini',  # Windows
    }
    delete_dirs = {
        'dist',  # default dist folder
        'node_modules',  # npm, yarn
        'bower_components',  # bower
        'build',  # generic build folder
        '.build',  # swift package manager
        'Pods',  # cocoapods (obj-c, swift)
        'Carthage',  # carthage (obj-c, swift)
        'CMakeFiles',  # cmake
        'CMakeScripts',  # cmake
        'venv',  # python (virtualenv, nodeenv)
        '.venv',  # python (virtualenv, nodeenv)
    }
    ignored_dirs = {
        '.git',
        '.hg',
        '.svn',
    }

    # check if input directory is actually a file
    if os.path.isfile(directory):
        if os.path.basename(directory) in delete_files:
            yield directory
        return

    for root, dirs, files in os.walk(directory, topdown=True):
        for file2 in filter(lambda f: f in delete_files or f.startswith('._'), files):
            yield os.path.join(root, file2)
        for dir2 in filter(lambda d: d in delete_dirs, dirs):
            yield os.path.join(root, dir2)
        dirs[:] = [d for d in dirs if d not in delete_dirs and d not in ignored_dirs]


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
