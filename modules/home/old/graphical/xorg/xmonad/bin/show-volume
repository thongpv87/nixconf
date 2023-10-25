#!/usr/bin/env sh
color=$1

amixer_out=$(amixer get Master | grep 'Front Left: Playback')
status=${amixer_out: -5}
vol=$(echo $amixer_out | awk -F '\\[|%' '{print $2}')


if [ "$status" = "[off]" ] ; then
    icon="ﱝ "
elif [ $vol -gt 75 ]; then
    icon=" "
elif [ $vol -le 75 ] && [ $vol -gt 50  ]; then
    icon="墳 " #"$vol"
elif [ $vol -le 50 ] && [ $vol -gt 15  ]; then
    icon=" "
# elif [ $vol -le 25 ] && [ $vol -gt 10  ]; then
#     icon="奔 "
elif [ $vol -le 15 ] && [ $vol -gt 0 ]; then
    icon="奄 "
else
    icon="ﱝ "
fi

printf "<fc=%s>%s </fc>" "$color" "$icon"
