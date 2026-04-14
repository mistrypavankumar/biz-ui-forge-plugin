# Biz UI Forge — Changelog

Tracks skill evolution: rule changes, feature additions, and structural updates.

---

## 2026-04-14 (update 3)

### Rules
- **Added** LR-022 — Always use AG Grid for tables (promoted from IMPL-005, high severity)

### Skill Features
- **Fixed** variant mode — added instructions + exit checklist (was empty)
- **Fixed** pre-response gate — removed hardcoded rule IDs, now reads learned-rules.md dynamically
- **Fixed** sequential thinking — added trivial-task escape hatch (skip for one-liners, `--learn list`, etc.)

### Net Result
- Rules: 14 → 15
- All modes now have instructions + exit checklists

## 2026-04-14 (update 2)

### Skill Features
- **Hardened** pre-response gate — now walks through each rule by ID with concrete checks (Iconify? AI comments? unused vars? hardcoded colors?) instead of generic "scan rules"
- **Hardened** success logging — defined trigger condition (user's next message is a new task, not a correction), format, and review integration

## 2026-04-14

### Rules
- **Added** LR-020 — Write comments like a developer, not like AI
- **Added** LR-021 — Extract the largest reusable boundary (promoted from IMPL-004, count >= 2)
- **Consolidated** LR-006 + LR-012 + LR-018 + LR-019 → **LR-IC** (single icon policy rule)
- **Merged** LR-001 + LR-003 + LR-004 → **LR-009** (single quality gate rule)
- **Merged** LR-008 → **LR-011** (unused vars cleanup — LR-011 is the superset)
- **Added** `Modes` field to all 14 rules (mode-specific filtering for pre-response gate)

### Skill Features
- **Added** pre-response self-check gate (scan learned rules before presenting output)
- **Added** exit checklists for all 7 modes (audit, suggest, check, redesign/build, fix, mockup, implement)
- **Added** Layer 4: success tracking (`successes-log.md`)
- **Added** `--learn review` sub-command (audit rules for duplicates, stale, pending promotions)
- **Added** mode-specific rule tags (`Modes` field in learned rule format)
- **Expanded** hook regex with 12 new correction patterns ("actually I wanted", "closer but", "why did you", etc.)
- **Created** `README.md` — quick-start reference
- **Created** `CHANGELOG.md` — this file

### Net Result
- Rules: 20 → 14 (consolidated, zero redundancy)
- All rules mode-tagged
- All corrections resolved (0 pending promotions)

## 2026-04-13

### Rules
- **Added** LR-015 — Decompose code following existing project structure
- **Added** LR-016 — Prioritize scalable foundations over convenience
- **Added** LR-017 — Backwards compatibility not required unless explicitly requested
- **Added** LR-018 — Always prefer react-icons; migrate shared components
- **Added** LR-019 — Never use emoji for icons; always use SVG or react-icons

## 2026-04-10

### Rules
- **Added** LR-011 — Fix unused variables in all touched and affected files
- **Added** LR-012 — Never use Iconify strings; always use react-icons
- **Added** LR-013 — Nav route checklist (9 files when adding a route)
- **Added** LR-014 — Avoid overfetching in mutation responses: return only `id`
- **Promoted** IMPL-006 → LR-012 (Iconify strings used despite LR-006)

### Corrections
- **Logged** IMPL-005 — Replaced AG Grid with custom MUI table (assumption-error)
- **Logged** IMPL-006 — Used Iconify strings instead of react-icons (style-drift, promoted)

## 2026-04-09

### Rules
- **Added** LR-010 — Create separate skeleton components for loading states

## 2026-04-07

### Rules
- **Added** LR-007 — SSRM tables must use invalidate with router.refresh()
- **Added** LR-008 — Remove unused code only in touched files
- **Added** LR-009 — Mandatory quality gate: eslint fix + type-check before done

## 2026-04-03

### Corrections
- **Logged** IMPL-003 — Created new component instead of following "same as X" pattern
- **Logged** IMPL-004 — Duplicated UI block instead of extracting shared component (count: 2)

## 2026-04-02

### Rules
- **Added** LR-001 — Auto-format touched files after writing code
- **Added** LR-002 — Pixel-match every mockup detail during implement mode
- **Added** LR-003 — Run type-check only on changed files
- **Added** LR-004 — Run eslint --fix without asking permission
- **Added** LR-005 — Read theme files first; use .main not .light
- **Added** LR-006 — Use varied react-icons families, not just Phosphor
- **Promoted** STYLE-001 → LR-001 (failed to auto-format)
- **Promoted** IMPL-002 → LR-002 (missed mockup details)
- **Promoted** TS-001 → LR-003 (TypeScript errors left unfixed)

### Corrections
- **Logged** STYLE-001 — Failed to auto-format files (promoted)
- **Logged** IMPL-002 — Incomplete mockup implementation (count: 3, promoted)
- **Logged** TS-001 — TypeScript errors left after UI implementation (promoted)

## 2026-04-01

### Corrections
- **Logged** IMPL-001 — Kept wrapper modal that conflicts with mockup layout

### Skill
- Initial hook setup (`detect-corrections.sh`)
- Initial self-improvement system (3-layer: hook → corrections → learned rules)
