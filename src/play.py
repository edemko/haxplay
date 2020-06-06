#!/usr/bin/env python3

import random
import subprocess
import sys

def main():
    try:
        args = getArgs()
        print("Ctrl+C to stop", file=sys.stderr)
        play(args.files, repeat=args.repeat, shuffle=args.shuffle)
    except KeyboardInterrupt:
        pass
    print("Finished.", file=sys.stderr)

def getArgs():
    import argparse
    parser = argparse.ArgumentParser(description="Play music files.")
    parser.add_argument("-s", "--shuffle", action='store_true')
    parser.add_argument("-r", "--repeat", action='store_true')
    parser.add_argument("files", metavar="FILE", nargs="*")
    return parser.parse_args()

def play(files, *, shuffle, repeat):
    while True:
        if shuffle:
            random.shuffle(files)
        success = False
        for file in files:
            print("Playing: {}".format(file), file=sys.stderr)
            success |= playOne(file)
        if not success:
            print("No files playable; exiting.", file=sys.stderr)
            return
        if not repeat:
            break


def playOne(file):
    try:
        subprocess.run(
              ["ffplay", "-nodisp", "-autoexit", file]
            , stdout=subprocess.DEVNULL
            , stderr=subprocess.DEVNULL
            , check=True
            )
    except subprocess.CalledProcessError:
        return False
    else:
        return True

if __name__ == "__main__":
    main()
