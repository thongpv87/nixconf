#!/usr/bin/env sh

# A dwm_bar function to show the current network connection/SSID, private IP, and public IP using NetworkManager
# Joe Standring <git@joestandring.com>
# GNU GPLv3

# Dependencies: NetworkManager, curl
active_color=$1
inactive_color=$2

conname=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}')
if [ "$conname" = "" ]; then
    conname=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-)
fi
#PRIVATE=$(nmcli -a | grep 'inet4 192' | awk '{print $2}')
#PUBLIC=$(curl -s https://ipinfo.io/ip)

if [ "$conname" != "" ]; then
    status=""
    color="$active_color"
else
    status="睊 "
    color="$inactive_color"
fi

printf "<fc=%s>%s </fc>" "$color" "$status"

# on-click
# x=$(nmcli -a | grep 'Wired connection' | awk 'NR==1{print $1}') && y=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -c 5-) && notify-send "Connected to $x$y"
