#!/usr/bin/env bash
if pgrep -f "quickshell.*Shell.qml" >/dev/null 2>&1; then
    qs -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call main forceReload 2>/dev/null || {
        pkill -f "quickshell.*Shell.qml" 2>/dev/null
        nohup quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml >/dev/null 2>&1 &
    }
else
    nohup quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml >/dev/null 2>&1 &
fi
