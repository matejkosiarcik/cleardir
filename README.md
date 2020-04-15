# ClearDir

> Clears directory from development and OS junk files

<!-- toc -->

## Installation

### Via package manager

Coming soon

### Manually

Just clone this repo and run `make install` (or `make install DESTDIR=/my/custom/dir`)

Better install method based on `setup.py`/`pip` is coming soon.

## Usage

```sh
$ cleardir --help
usage: main.py [-h] [-n] [-f] [-v] [paths [paths ...]]

positional arguments:
  paths          directories to clear (also accepts filepaths)

optional arguments:
  -h, --help     show this help message and exit
  -n, --dry-run  do not remove files, only print what would be deleted
  -f, --force    actually perform file/directory removal
  -v, --verbose  additional logging output
```

## Current milestones

- [ ] Improve testing (pytest)
- [ ] Add install script
- [ ] Release on pypi/brew
- [ ] Compile to native executable
- [ ] Replace shell `find` with pure python
- [ ] Consider docker
- [ ] Interactive mode
- [ ] Add flag to specify paths which not to delete
- [ ] Use `dot_clean` where available
