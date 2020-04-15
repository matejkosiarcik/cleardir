#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
import shutil
import functools
from typing import List, Iterable
import logging
import itertools

log = logging.getLogger('main')


# Main function
def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument( '-n', '--dry-run', action='store_true',
                        help='do not remove files, only print what would be deleted')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='additional logging output')
    parser.add_argument('paths', nargs='*', help='directories to clear (also accepts filepaths)')
    # TODO: add -i/--interactive flag (similar to `git clean -i`)
    # TODO: add -q/--quiet flag
    # TODO: add -V/--version flag (probably after first deployment)
    # TODO: add -k,--keep flag to keep certain files
    # TODO: add -a,--add flag to add additional files for deletion
    # TODO: add -f,--force flag
    # TODO: discontinue usage without one of -n/-i/-f flags (similar to `git clean`)
    args = parser.parse_args(argv)

    # if args.verbose and args.quiet:
    #     print('Can\'t accept both "quiet" and "verbose" flags.', file=sys.stderr)
    #     return 1

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

    dry_run = args.dry_run
    for directory in directories:
        process_directory(directory, dry_run)
    return 0


# Process single directory
def process_directory(directory: str, dry_run: bool):
    if not os.path.exists(directory):
        log.info('Could not find %s' % directory)
        return
    log.info('Processing %s' % directory)

    for file in find_files(directory):
        if dry_run:
            print('Would remove %s' % file)
        else:
            print('Removing %s' % file)
            try:
                delete(file)
            except FileNotFoundError:
                pass

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
    command = ['find', dir] + files_for_find()
    log.debug('Executing: %s' % ' '.join(command))
    process = subprocess.Popen(command, stdout=subprocess.PIPE)
    for line in process.stdout:
        file = str(line.decode('utf-8').strip())
        yield file
    process.communicate()


# returns generic list of files to add to "find" command
def files_for_find() -> Iterable[str]:
    delete_files = [
        '.DS_Store',  # macOS
        '.localized',  # macOS
        'CMakeCache.txt',  # cmake
        '._*',  # dotbar macos/BSD files
    ]
    delete_files = (['-name', x, '-type', 'f'] for x in delete_files)

    delete_folders = [
        # 'dist',  # general, node
        # 'public',  # general, node
        # 'build',  # general
        'node_modules',  # npm, yarn
        'bower_components',  # bower
        '.build',  # swift package manager
        'Pods',  # cocoapods (obj-c, swift)
        'Carthage',  # carthage (obj-c, swift)
        # 'target',  # rust
        'CMakeFiles',  # cmake
        'CMakeScripts',  # cmake
        'venv',  # python (virtualenv, pyenv)
        '.venv',  # python (virtualenv, pyenv)
    ]
    delete_folders = (['-name', x, '-type', 'd', '-prune'] for x in delete_folders)
    delete_all = functools.reduce(lambda all, el: all + ['-or'] + el, itertools.chain(delete_folders, delete_files))

    ignored_folders = [
        '.git',
        '.hg',
        '.svn',
    ]
    ignored_folders = (['-path', "*/%s/*" % x, '-prune'] for x in ignored_folders)
    ignore_all = functools.reduce(lambda all, el: all + ['-or'] + el, ignored_folders)

    return ['-not', '('] + ignore_all + [')', '-and', '('] + delete_all + [')']


if __name__ == "__main__":
    main(sys.argv[1:])
