#!/usr/bin/env sh

# A dwm_bar function to read the battery level and status
# Joe Standring <git@joestandring.com>
# GNU GPLv3

# Change BAT1 to whatever your battery is identified as. Typically BAT0 or BAT1
charge=$(cat /sys/class/power_supply/BAT0/capacity)
status=$(cat /sys/class/power_supply/BAT0/status)

normal_color=$1
low_battery_color=$2
charging_color=$3

color="$normal_color"
if [ "$status" = "Charging" ]; then
    icon=" " #"$CHARGE" "+" #🔌
    color="$charging_color"
elif [ "$status" = "Unknown" ]; then
    icon=" "
    color="$charging_color"
elif [ $charge - gt 80 ]; then
    icon=" "
elif [ $charge -le 80 ] && [ $charge -gt 50  ]; then
    icon=" " #"$charge"
elif [ $charge -le 50 ] && [ $charge -gt 30  ]; then
    icon=" " #"$charge"
elif [ $charge -le 30 ] && [ $charge -gt 15  ]; then
    icon=" " #"$charge"
elif [ $charge -le 15 ]; then
    icon=" !"
    color="$low_battery_color"
else
    icon=" "
    color="$charging_color"
fi

echo "<fc=${color}>$icon $charge%</fc>"
