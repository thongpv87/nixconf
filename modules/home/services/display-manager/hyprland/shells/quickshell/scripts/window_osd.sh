#!/usr/bin/env bash

# Zombie prevention
for pid in $(pgrep -f "window_osd.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

cleanup() {
    pkill -P $$ 2>/dev/null
}
trap cleanup EXIT SIGTERM SIGINT

print_osd() {
    ws=$(timeout 2 hyprctl activeworkspace -j 2>/dev/null | jq '.id' 2>/dev/null)
    active_addr=$(timeout 2 hyprctl activewindow -j 2>/dev/null | jq -r '.address' 2>/dev/null)

    if [ -z "$ws" ] || [ -z "$active_addr" ] || [ "$ws" == "null" ]; then return; fi

    timeout 2 hyprctl clients -j 2>/dev/null | jq --unbuffered -c --arg ws "$ws" --arg addr "$active_addr" '
        map(select(.workspace.id == ($ws|tonumber)))
        | sort_by(.at[0])
        | {
            count: length,
            activeIdx: (map(.address == $addr) | index(true) // 0)
          }
    '
}

# Initial print
print_osd

# Listen to focus change socket events
while true; do
    socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
        case "$line" in
            activewindow*|activewindowv2*|focuswindow*|workspace*)
                while read -t 0.05 -r extra_line; do
                    continue
                done
                print_osd
                ;;
        esac
    done
    sleep 1
done
