---
id: ep-2026-02-23-c8e22caf
type: episode
title: >-
  Take a look at current monitor setup. I have two monitor, eDP-1 is laptop
  bui...
date: '2026-02-23T09:06:03.338Z'
tags:
  - imported
  - claude-code
  - 'session:a0cbad04-672e-4fa9-9422-8dc51c043fa6'
outcome: success
related_files:
  - >-
    /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/default.nix
  - /home/thongpv87/Code/nixconf/modules/home/apps/rofi/theme.rasi
  - /home/thongpv87/Code/nixconf/modules/home/apps/rofi/default.nix
  - >-
    /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/waybar/default.nix
  - >-
    /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/hypridle.conf
related_memories: []
session: a0cbad04-672e-4fa9-9422-8dc51c043fa6
---
## Summary
Imported from Claude Code session `a0cbad04`.
Branch: `master`.
Duration: 1h 29m.
120 user messages, 98 tool calls.

## Task
Take a look at current monitor setup. I have two monitor, eDP-1 is laptop builtin, DP-1 and DP-2 are different laptop dp port, I always use those port connect to the same monitor. 

Problem: Currently, both setup is the same that the external monitor is above the laptop monitor.

I want when connect the laptop to DP-1, it display my laptop on the right of external monitor (bottom aligned). DP-2 stay the same

## Files Modified
- /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/default.nix
- /home/thongpv87/Code/nixconf/modules/home/apps/rofi/theme.rasi
- /home/thongpv87/Code/nixconf/modules/home/apps/rofi/default.nix
- /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/waybar/default.nix
- /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/hypridle.conf

## Session Conclusion
The static monitor config now uses **scale 1.6** and the correct dual-monitor positions directly. This means:

- **Boot with external monitor**: Hyprland applies the correct layout immediately, no flash
- **Boot without external**: eDP-1 starts at 1.6 for ~0.5s, then the script corrects it to 1.0
- **Hotplug**: script handles it as before
