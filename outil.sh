#! /bin/sh
CURDIR="$(dirname "$0")"
CURDIR=$(
    while [ \! -f main.sh ]; do
        cd ..
        if test "$PWD" = /; then echo $CURDIR; exit; fi # I tried so hard and go so far, but in the end it doesn't even matter
    done
    echo "$PWD"
)
DEFAULT_SINK=$( echo $(pacmd list | grep 'Default sink' | cut -d':' -f2) )
