---
id: ep-2026-02-21-969f26a8
type: episode
title: Fix hypridle/hyprlock configuration for screen lock and idle management
date: '2026-02-21T13:47:35.853Z'
tags:
  - nixconf
  - hyprland
  - hypridle
  - hyprlock
  - idle-management
outcome: success
related_files:
  - modules/home/services/display-manager/hyprland/default.nix
  - modules/home/services/display-manager/hyprland/hypridle.conf
related_memories: []
---
## Summary
Fixed hyprland idle management configuration in nixconf project. The system wasn't locking or properly managing idle timeouts.

## What Was Done
1. Uncommented `hyprlock` package in `default.nix` (was commented out, so lock screen was never available)
2. Rewrote `hypridle.conf` with proper structure:
   - Added `general` block with `lock_cmd`, `unlock_cmd`, `before_sleep_cmd`, `after_sleep_cmd`
   - Lock at 20 min (1200s) via `loginctl lock-session`
   - DPMS off at 30 min (1800s)
   - Suspend at 45 min (2700s)
3. Used `pidof hyprlock || hyprlock` pattern to prevent duplicate instances
4. Used `loginctl lock-session` → `lock_cmd` pattern for proper systemd integration

## Lessons
- hypridle's `general` block `lock_cmd`/`unlock_cmd`/`before_sleep_cmd` are essential for proper lock integration
- `loginctl lock-session` is preferred over directly calling `hyprlock` in listeners
- `pidof hyprlock || hyprlock` prevents duplicate lock instances
