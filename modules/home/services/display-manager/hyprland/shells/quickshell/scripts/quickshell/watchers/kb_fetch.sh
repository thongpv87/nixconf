#!/usr/bin/env bash

if command -v fcitx5-remote >/dev/null; then
  engine=$(fcitx5-remote -n 2>/dev/null)
  if [ "$engine" = "bamboo" ]; then
    echo "VN"
    exit 0
  elif [ -n "$engine" ]; then
    echo "EN"
    exit 0
  fi
fi

layout=$(LC_ALL=C hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // .keyboards[0].active_keymap // empty' | head -n1)
[[ -z "$layout" || "$layout" == "null" ]] && layout="US"
echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]'
