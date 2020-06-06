#!/usr/bin/env python3

import sys

def main():
    """
    WARNING: delete all `*.files` file in the pwd to make space for the results
    goes through hash-filename lines (as produced by`sha*sum`)
    if any hash is seen more than once, the associated filenames are echoed to a file in the pwd with the named `<hash>.files`
    any hashes that were seen exactly once are echoed to a file `unique.files`
    """
    db = dict()
    # generate the duplicate files
    for line in sys.stdin.readlines():
        cutpoint = line.find(' ')
        hash = int(line[:cutpoint], 16)
        fname = line[cutpoint:].strip()
        try:
            db[hash].add(fname)
        except KeyError:
            db[hash] = HashState(hash, fname)
    # generate the `unique.files` file
    with open("unique.files", 'wt') as fp:
        for state in db.values():
            state.finish(fp)

class HashState:
    def __init__(self, hash1, file1):
        self._hash = hash1
        self._file1 = file1
        self._unique = True

    def add(self, newfile):
        # alight to 128 is for 512-bit hashes; change as appropriate
        with open("{:0>128x}.files".format(self._hash), 'at') as fp:
            if self._unique:
                self._unique = False
                print(self._file1, file=fp)
                print(newfile, file=fp)
            else:
                print(newfile, file=fp)

    def finish(self, fp):
        if self._unique:
            print(self._file1, file=fp)


if __name__ == "__main__":
    main()
