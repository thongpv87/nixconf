---
id: ep-2026-02-23-7a6adffe
type: episode
title: Can you check why hyprpaper and waybar is not autostarted when system startup?
date: '2026-02-23T09:06:03.322Z'
tags:
  - imported
  - claude-code
  - 'session:4f7401e7-bc9e-4bf7-a2aa-22487c92d990'
outcome: success
related_files:
  - /home/thongpv87/.claude/plans/harmonic-juggling-cookie.md
related_memories: []
session: 4f7401e7-bc9e-4bf7-a2aa-22487c92d990
---
## Summary
Imported from Claude Code session `4f7401e7`.
Branch: `master`.
Duration: 7m.
40 user messages, 39 tool calls.

## Task
Can you check why hyprpaper and waybar is not autostarted when system startup?

## Files Modified
- /home/thongpv87/.claude/plans/harmonic-juggling-cookie.md

## Session Conclusion
Here's what I found:

**The core issue**: `graphical-session.target` is never activated in the current boot. Both waybar and hyprpaper are systemd services that depend on this target, so they never start.

**Why**: Your system has UWSM enabled (in `modules/system/graphical/wayland/hyprland.nix`), which is supposed to activate `graphical-session.target`. But Hyprland's own systemd integration is disabled in home-manager (`systemd.enable = false` at line 208) to avoid conflicts with UWSM. The problem is **UWSM isn't actually running** — GDM launches Hyprland directly, bypassing UWSM entirely....
