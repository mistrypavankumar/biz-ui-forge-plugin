# Skill Evolution Protocol

This protocol governs how `biz-ui-forge` learns from its mistakes over time.

## 1. When to Log a Correction

Log an entry in `corrections-log.md` when **any** of these occur:

- The user explicitly corrects your output ("no, not that", "I said X not Y", "you forgot Z")
- The user asks you to redo something you already attempted
- The user points out the same category of mistake that was made before (even if the specific instance is different)
- You catch yourself making a mistake that contradicts existing skill rules

**Do NOT log**: stylistic preferences that are purely subjective and already one-off (e.g., "make it slightly darker"). Only log if it reflects a repeatable behavioral pattern.

## 2. How to Log

1. Check `corrections-log.md` for an existing entry that matches the same root cause.
2. If a match exists: increment `count` and update the date.
3. If no match: add a new entry at the top with `count: 1`.
4. Use a short descriptive ID like `HARDCODED_COLOR`, `SKIPPED_CHILD_UPDATE`, `MISSED_EMPTY_STATE`.

## 3. When to Promote Corrections into Skill Rules

Promotion criteria (any one is sufficient):
- **count >= 2** — the same mistake happened twice or more
- **High severity** — the mistake caused significant rework (full zone redo, broken logic, lost business data)
- **User explicitly says "always do X"** — direct instruction for permanent behavior change

## 4. How to Promote

1. Identify which section of `SKILL.md` the correction belongs to (non-negotiable rules, mode instructions, constraints, etc.)
2. Draft a concise rule that prevents the mistake
3. Add the rule to `SKILL.md` in the appropriate section
4. Mark the correction entry as `[PROMOTED]` and note where it was added
5. If the correction affects a specific mode's playbook (e.g., `implement-playbook.md`), update that file too

## 5. Periodic Review (User-Triggered)

When the user asks to "improve the skill" or "review corrections":

1. Read all `active` entries in `corrections-log.md`
2. Group by root cause category
3. Identify entries meeting promotion criteria
4. Propose specific SKILL.md additions/edits for user approval
5. After approval, apply changes and mark entries as `[PROMOTED]`
6. Report: how many corrections reviewed, how many promoted, what rules were added

## 6. Categories for Root Cause

Use these standard categories when logging:

| Category | Description |
|----------|-------------|
| `theme-violation` | Hardcoded colors, spacing, or tokens instead of using theme |
| `skipped-zone` | Missed a visible zone from the mockup |
| `skipped-child` | Stopped at parent, didn't update child component that owns the zone |
| `skipped-state` | Missed hover, empty, loading, error, disabled, or dark mode state |
| `logic-destroyed` | Overwrote business logic, handlers, or data contracts |
| `wrong-mode` | Chose the wrong mode for the request |
| `wrong-component` | Used a new component instead of an existing project component |
| `assumption-error` | Made up data, props, or conventions that don't exist in the codebase |
| `incomplete-phase` | Left a zone half-implemented before moving to the next |
| `style-drift` | Output diverged from the mockup/reference without reason |
| `framework-leak` | Used Tailwind/Bootstrap/other framework in mockup instead of pure CSS |
| `other` | Doesn't fit above — describe in the entry |
