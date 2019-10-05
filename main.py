#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
import shutil
import functools
from typing import List, Iterable


# Logging
log = lambda *args: None


def init_logging(flag: bool):
    global log
    if flag:
        log = real_log


def real_log(*args):
    line = ' '.join(args)
    print(line, file=sys.stderr)


# Main function
def main(argv: Iterable[str]):
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--dry-run', action='store_true',
                        help='Don\'t remove files, only print what would be deleted')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Additional logging output')
    parser.add_argument('-V', '--version', action='store_true',
                        help='Print program version')
    parser.add_argument('list', nargs='*', help='Directories to clear')
    try:
        args = parser.parse_args(list(argv))
    except argparse.ArgumentError:
        return 1
    except argparse.ArgumentTypeError:
        return 1
    except SystemExit:
        return 0

    if args.version:
        print('cleardir version: dev')
        return 0

    directories = args.list
    if directories is None:
        directories = ['.']
    directories = [x for x in directories if len(x) > 0]
    if len(directories) == 0:
        directories = ['.']
    assert isinstance(directories, list)

    dry_run = args.dry_run
    init_logging(args.verbose)
    for directory in directories:
        process_dir(directory, dry_run)
    return 0


# Process single directory
def process_dir(dir: str, dry_run: bool):
    if not os.path.exists(dir):
        print('Could not find "%s"' % dir, file=sys.stderr)
        return

    log('Processing "%s"' % dir)

    has_dot_clean = False
    try:
        subprocess.check_call(['command', '-v', 'dot_clean'],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        has_dot_clean = True
    except subprocess.CalledProcessError:
        pass

    if has_dot_clean and not dry_run:
        subprocess.check_call(['dot_clean', '-m', dir])

    command = find_command(dir, not has_dot_clean or dry_run)

    process = subprocess.Popen(command,
                               stdout=subprocess.PIPE)
    for line in process.stdout:
        file = str(line.decode('utf-8').strip())
        if dry_run:
            print(file)
        else:
            try:
                delete(file)
                log('Deleted "%s"' % file)
            except FileNotFoundError:
                log('Skipping "%s"' % file)
                pass
    process.communicate()


# deletes file(or folder/symlink) from filesystem
def delete(entry: str):
    if os.path.exists(entry):
        subprocess.check_call(['rm', '-rf', entry])
    else:
        raise FileNotFoundError("file: %s exists" % entry)


# creates complete "find" command to run
def find_command(dir: str, include_underbar_files: bool) -> Iterable[str]:
    command = ['find', '-L', dir] + files_for_find()
    if include_underbar_files:
        command += ['-or', '-name', "'._*'", '-type', 'f']
    return command


# returns generic list of files to add to "find" command
def files_for_find() -> Iterable[str]:
    files = [
        '.DS_Store',  # mac
        '.localized',  # mac
        'CMakeCache.txt',  # cmake
    ]
    files = [['-name', x, '-type', 'f'] for x in files]

    folders = [
        'build',  # general
        'node_modules',  # npm, yarn
        'bower_components',  # bower
        '.build',  # spm
        'Pods',  # cocoapods
        'Carthage',  # carthage
        'target',  # rust
        'CMakeFiles',  # cmake
        'CMakeScripts',  # cmake
        'venv',  # pyenv
        '.venv',  # pyenv
    ]
    folders = [['-name', x, '-type', 'd', '-prune'] for x in folders]

    return functools.reduce(lambda el, rest: el + ['-or'] + rest, folders + files)


if __name__ == "__main__":
    main(sys.argv[1:])
