#!/usr/bin/env bash

# Reload Hyprland colors
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Reload Quickshell UI
if [ -f "$HOME/.config/hypr/scripts/reload.sh" ]; then
    bash "$HOME/.config/hypr/scripts/reload.sh" >/dev/null 2>&1 || true
fi

# Send notification if dunstify is available
if command -v dunstify >/dev/null 2>&1; then
    dunstify -r 9991 -a "Matugen" "Theme Applied" "Color palette updated from wallpaper" || true
fi
