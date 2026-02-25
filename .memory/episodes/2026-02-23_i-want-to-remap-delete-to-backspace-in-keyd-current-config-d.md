---
id: ep-2026-02-23-3c2bd872
type: episode
title: >-
  I want to remap delete to backspace in keyd, current config doesn't seem
  working
date: '2026-02-23T09:06:03.314Z'
tags:
  - imported
  - claude-code
  - 'session:3a922039-772d-493d-a1d6-433446906a1b'
outcome: success
related_files: []
related_memories: []
session: 3a922039-772d-493d-a1d6-433446906a1b
---
## Summary
Imported from Claude Code session `3a922039`.
Branch: `master`.
Duration: 10h 33m.
7 user messages, 3 tool calls.

## Task
I want to remap delete to backspace in keyd, current config doesn't seem working

## Session Conclusion
I can't run `sudo` here. Could you run this in your terminal?

```
sudo keyd monitor
```

Press your Delete key and paste the output. It will show the actual key name keyd recognizes (e.g., `delete`, `kpdelete`, or a raw scancode). Once we know the real key name, we can fix the mapping.
