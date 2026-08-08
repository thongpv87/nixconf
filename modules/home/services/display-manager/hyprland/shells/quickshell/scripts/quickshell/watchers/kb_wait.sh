#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

PIPE="$QS_RUN_DIR/qs_kb_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    LC_ALL=C socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock 2>/dev/null | grep --line-buffered "activelayout>>" > "$PIPE" &
fi

dbus-monitor "interface='org.fcitx.Fcitx.Controller1'" "interface='org.kde.StatusNotifierItem'" 2>/dev/null | grep --line-buffered -E "SetCurrentIM|Toggle|NewIcon|NewItem" > "$PIPE" &

read -r _ < "$PIPE"
sleep 0.3
