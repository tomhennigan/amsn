#!/bin/sh
# Written by:   Alexandre Hamelin (ahamelin users sourceforge net)
# Date:         Sept 15, 2003
# Usage:        ./dups.sh language_file
#
# Report duplicated keys for a given language file.

if [ $# -ne 1 ]; then
    echo "usage: `basename $0` language_file"
    exit 1
fi

LANGFILE="$1"

awk '{print $1}' < "$LANGFILE" | sort | uniq -c | grep -v '^ *1'
