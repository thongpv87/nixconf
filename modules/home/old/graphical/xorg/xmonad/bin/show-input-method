#!/usr/bin/env sh

en_color=$1
vi_color=$2
other_color=$3

engine=$(ibus engine)
color="$en_color"
layout="US"

if [ $? -eq 0 ]; then
    case "$engine" in
        "xkb:us:eng")
            layout="EN"
            color=$en_color
            ;;
        "Bamboo")
            layout="VI"
            color=$vi_color
            ;;
        *)
            language=${engine:4:2}
            layout=${language^^}
            color=$other_color
            ;;
    esac
fi

printf "<fc=%s> %s </fc>" "$color" "$layout"
