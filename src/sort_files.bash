#!/bin/bash
set -e

HERE="$(dirname "$0")"

dry=1
while getopts "y" opt; do
    case "$opt" in
        y)  dry=0
            ;;
        esac
done
shift $((OPTIND-1))
case $# in
    1)
        START_DIR=`pwd`
        TARGET_DIR="$1"
    ;;
    2)
        START_DIR="$1"
        TARGET_DIR="$2"
    ;;
    *) exit 1
    ;;
esac


lookup_artist() {
    local F="$1"
    local info="$(mp3info -p '%a' "$F" 2>/dev/null)"
    if [ -z "$info" ]; then
        info="$(ffprobe 2>&1 "$F" | grep '^    artist\s*:' | sed -r 's/^    artist\s*: //')"
    fi
    info="$(echo "$info" | sed 's@/@-@g' | sed 's/^\.//')"
    if [ -z "$info" ]; then info='_unknown_'; fi
    echo "$info"
}
lookup_album() {
    local F="$1"
    local info="$(mp3info -p '%l' "$F" 2>/dev/null)"
    if [ -z "$info" ]; then
        info="$(ffprobe 2>&1 "$F" | grep '^    album\s*:' | sed -r 's/^    album\s*: //')"
    fi
    info="$(echo "$info" | sed 's@/@-@g' | sed 's/^\.//')"
    info="$(echo "$info" | sed 's/^ *//' | sed 's/ *$//')"
    if [ -z "$info" ]; then info='_unknown_'; fi
    echo "$info"
}
lookup_track() {
    local F="$1"
    local info="$(mp3info -p '%n' "$F" 2>/dev/null)"
    if [ -z "$info" ]; then
        info="$(ffprobe 2>&1 "$F" | grep '^    track\s*:' | sed -r 's/^    track\s*: //' | sed 's@/.*$@@')"
    fi
    info="$(echo "$info" | sed 's/^0*//')"
    info="$(printf '%02d' "$info")"
    if [ "$info" = '00' ]; then info='_unknown_'; fi
    echo "$info"
}
lookup_title() {
    local F="$1"
    local info="$(mp3info -p '%t' "$F" 2>/dev/null)"
    if [ -z "$info" ]; then
        info="$(ffprobe 2>&1 "$F" | grep '^    title\s*:' | sed -r 's/^    title\s*: //')"
    fi
    info="$(echo "$info" | sed 's/^ *//' | sed 's/ *$//')"
    info="$(echo "$info" | sed 's@/@-@g')"
    if [ -z "$info" ]; then info='_unknown_'; fi
    echo "$info"
}

guess_title() {
    local x="$1"
    x="$(basename "$x" | sed -r 's/^(([0-9]\.)?[0-9]+ - )+//')"
    while echo "$x" | grep -q '\.mp3$'; do
        x="${x%.mp3}"
    done
    if echo "$x" | grep -qP '^([0-9]\.)?[0-9]{2} .+'; then
        x="$(echo "$x" | sed 's/^.. //')"
    fi
    if [ -z "$x" ]; then x='_unknown_'; fi
    echo "$x"
}
guess_track() {
    local x="$1"
    local disk=''
    x="$(basename "$x")"
    while echo "$x" | grep -q '^00 - '; do
        x="${x#'00 - '}"
    done
    if echo "$x" | grep -qP '^([0-9]\.)?[0-9]{2} '; then
        disk="$(echo "$x" | sed -r 's/^(([0-9])\.)?([0-9]{2}) .*/\2/')"
        x="$(echo "$x" | sed -r 's/^(([0-9])\.)?([0-9]{2}) .*/\3/')"
    else
        x=_unknown_
    fi
    if [ -n "$disk" ]; then x="${disk}.${x}"; fi
    echo "$x"
}

missing=0
guessed=0
IFS=$'\n'
for F in $(find "$START_DIR" -iname '*.mp3'); do
    echo "$F" >&2

    # perform lookup
    artist="$(lookup_artist "$F")"
    album="$(lookup_album "$F")"
    track="$(lookup_track "$F")"
    title="$(lookup_title "$F")"

    # record missing tags and guess based on filename
    out="${artist}/${album}/${track} - ${title}.mp3"
    if echo "$out" | grep -qF '_unknown_'; then
        missing=$(( missing + 1 ))
        color=f80
        if [ "$title" = '_unknown_' ]; then
            title="$(guess_title "$F")"
        fi
        if [ "$track" = '_unknown_' ]; then
            track="$(guess_track "$F")"
        fi
        # record if guessing was successful
        out="${artist}/${album}/${track} - ${title}.mp3"
        if echo "$out" | grep -vqF '_unknown_'; then
            guessed=$(( guessed + 1 ))
            color=08f
        fi
    else
        color=080
    fi
    if [ "${track}" = _unknown_ ]; then track=00; fi
    out="${artist}/${album}/${track} - ${title}.mp3"
    track="$(echo "$track" | sed -r 's/^[0-9]\.//')"

    technicolor "$color" "    $out" >&2

    # move tracks and tag
    if [ "$dry" != '1' ]; then
        [ "$artist" = _unknown_ ] || mp3info -a "$artist" "$F"
        [ "$album" = _unknown_ ] || mp3info -l "$album" "$F"
        [ "$track" = 00 ] || mp3info -n "$track" "$F"
        [ "$title" = _unknown_ ] || mp3info -t "$title" "$F"
        mkdir -p "$(dirname "${TARGET_DIR}/${out}")"
        mv "$F" "${TARGET_DIR}/${out}"
    fi
done

if [ $missing -ne 0 ]; then
    technicolor f80 >&2 "Tracks missing fields: $missing"
    technicolor 08f >&2 "Guessed fields for: $guessed"
fi
