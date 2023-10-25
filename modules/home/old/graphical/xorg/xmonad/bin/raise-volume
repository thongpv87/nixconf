#!/usr/bin/env bash
[ $(amixer get Master | grep 'Front Left: Playback' | awk -F '\\[|%' '{print $2}') -lt 100 ] && pactl set-sink-volume @DEFAULT_SINK@ +5%
