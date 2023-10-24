#!/usr/bin/env bash
x=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}') && y=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-) && notify-send "Connected to $x$y"
