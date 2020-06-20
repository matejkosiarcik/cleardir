# ClearDir

> Clears directory from development and OS junk files

<!-- toc -->

- [About](#about)
- [Installation](#installation)
  - [Via package manager](#via-package-manager)
  - [Manually](#manually)
- [Usage](#usage)
- [Future milestones](#future-milestones)

<!-- tocstop -->

## About

`cleardir` is a directory cleaner that removes development files and folders
(such as `node_modules`) and OS junk files (such as `.DS_Store`).

Written in *python3*.
Future plan is to be compatible with *python2.7* as well.

## Installation

### Via package manager

Coming soon

### Manually

Just clone this repo and run `make install` (or `make install DESTDIR=/my/custom/dir`).

Better install method based on `setup.py`/`pip` is coming soon.

## Usage

To clean current working directory interactively run `cleardir -i .`.

The list of all options:

```txt
$ cleardir --help
usage: cleardir [-h] [-n] [-f] [-i] [-v] [paths [paths ...]]

positional arguments:
  paths              directories to clear (also accepts filepaths)

optional arguments:
  -h, --help         show this help message and exit
  -n, --dry-run      do not remove files, only print what would be deleted
  -f, --force        force remove all matching files
  -i, --interactive  work in interactive mode (ask user for each file whether
                     to remove it or not)
  -v, --verbose      additional logging output
```

## Future milestones

- [ ] Improve testing (with pytest)
- [ ] Finish setup.py
- [ ] Release on pypi
- [ ] Release on brew
