---
id: ep-2026-02-23-7fde5f49
type: episode
title: >-
  sed -i 's/windowrulev2/windowrule/g; s/class:/match:class /g;
  s/title:/match:...
date: '2026-02-23T09:06:03.328Z'
tags:
  - imported
  - claude-code
  - 'session:619b81bd-a9c1-4cbf-905b-e54bf611cb05'
outcome: success
related_files:
  - >-
    /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/extra.conf
related_memories: []
session: 619b81bd-a9c1-4cbf-905b-e54bf611cb05
---
## Summary
Imported from Claude Code session `619b81bd`.
Branch: `ai-experiment`.
Duration: 10m.
21 user messages, 15 tool calls.

## Task
sed -i 's/windowrulev2/windowrule/g; s/class:/match:class /g; s/title:/match:title /g; s/initialTitle:/match:initialTitle /g; s/, tag:/, match:tag /g; s/fullscreen:1/match:fullscreen 1/g; s/floating:1/match:floating 1/g' ~/.config/hypr/configs/WindowRules.conf

sed -i 's/noblur,/noblur 1,/g; s/center,/center 1,/g; s/float,/float 1,/g; s/pin,/pin 1,/g; s/keepaspectratio,/keepaspectratio 1,/g; s/fullscreen,/fullscreen 1,/g; s/noinitialfocus,/no_initial_focus 1,/g' ~/.config/hypr/configs/WindowRules.conf

sed -i '/idleinhibit/d; s/noblur/no_blur/g; s/initialTitle/initial_title/g; s/keepaspectratio/keep_aspect_ratio/g' ~/.config/hypr/configs/WindowRules.conf

Those are rule migrate extra.conf to new config. Do it 

## Files Modified
- /home/thongpv87/Code/nixconf/modules/home/services/display-manager/hyprland/extra.conf

## Session Conclusion
Now let me verify the `default.nix` windowrules are also correct. Looking at lines 246-260, they already use the new syntax (`match:class`, `float on`, `stayfocused on`, etc.) and `layerrule` uses `match:namespace`. Those look correct for 0.53.

The `extra.conf` is now fully migrated to the new 0.53 windowrule syntax:
- `floating:0` → `match:floating 0`
- `onworkspace:w[tv1]` → `match:onworkspace w[tv1]`  
- `onworkspace:f[1]` → `match:onworkspace f[1]`
- Matchers reordered before rules

The `default.nix` windowrules were already in the new format.

Sources:
- [0.53 Window/Layerrule convert...
