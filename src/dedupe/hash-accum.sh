#!/bin/bash
set -e

# recommended usage: hash-accum.sh <DIR> | tee hashes.txt

find -L "$1" -type f | xargs -d $'\n' sha512sum
