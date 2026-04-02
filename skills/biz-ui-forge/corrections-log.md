# Biz UI Forge — Corrections Log

Raw corrections are auto-captured by the hook into `corrections-log.jsonl`. This file is the **structured, human-readable** version where Claude logs analyzed corrections with root cause and correct behavior.

## How this works

1. **Hook** (`detect-corrections.sh`) catches correction-like messages and appends raw text to `corrections-log.jsonl`
2. **Claude** analyzes the correction, identifies root cause, and logs a structured entry here
3. **Periodic review** — user says "review corrections" or "improve the skill" to trigger promotion
4. **Promotion** — repeated corrections (count >= 2) get distilled into `learned-rules.md`

---

## Corrections

<!-- 
Add new entries at the top:

### [SHORT_ID] — Brief title
- **Date**: YYYY-MM-DD
- **Mode**: mockup | implement | fix | audit | redesign | build
- **What happened**: What Claude did wrong
- **User correction**: What the user said
- **Root cause**: Category + why it happened
- **Correct behavior**: What should have been done
- **Count**: N
- **Status**: active | promoted | obsolete
-->

<!-- No corrections logged yet. -->
