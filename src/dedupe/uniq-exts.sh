#!/bin/bash
set -e

sed <"$1" -r 's/^.*\.([^.]+)$/\1/' | sort -u >"$(dirname "$1")/exts.txt"
