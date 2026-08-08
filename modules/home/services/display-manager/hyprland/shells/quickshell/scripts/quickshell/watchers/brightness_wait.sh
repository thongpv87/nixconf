#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

PIPE="$QS_RUN_DIR/qs_brightness_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null
trap 'rm -f "$PIPE"; kill $MONITOR_PID 2>/dev/null; exit 0' EXIT INT TERM

if command -v inotifywait >/dev/null 2>&1; then
    LC_ALL=C inotifywait -q -e modify /sys/class/backlight/*/brightness 2>/dev/null > "$PIPE" &
    MONITOR_PID=$!
elif command -v udevadm >/dev/null 2>&1; then
    LC_ALL=C udevadm monitor --subsystem-match=backlight 2>/dev/null > "$PIPE" &
    MONITOR_PID=$!
fi

timeout 10 grep -m 1 "." < "$PIPE" > /dev/null
