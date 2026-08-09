# Single-instance guard: kill any duplicate running instances
pids=$(pgrep -f "quickshell.*Shell.qml")
if [ $(echo "$pids" | wc -w) -gt 1 ]; then
    echo "$pids" | head -n -1 | xargs -r kill -9 2>/dev/null
fi

if pgrep -f "quickshell.*Shell.qml" >/dev/null 2>&1; then
    qs -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call main forceReload 2>/dev/null || {
        pkill -f "quickshell.*Shell.qml" 2>/dev/null
        nohup quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml >/dev/null 2>&1 &
    }
else
    nohup quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml >/dev/null 2>&1 &
fi
