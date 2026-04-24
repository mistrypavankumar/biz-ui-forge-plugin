<div align="center">

# Biz UI Forge

**Enterprise UI skill for Claude Code — a self-improving, mode-driven system for designing, implementing, reviewing, and fixing frontend interfaces with senior-engineer discipline.**

[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-6950E8.svg)](https://claude.com/claude-code)
[![Modes](https://img.shields.io/badge/modes-12-43853d.svg)](#modes)
[![Learned Rules](https://img.shields.io/badge/learned%20rules-27-3178c6.svg)](./learned-rules.md)
[![Corrections](https://img.shields.io/badge/tracked%20corrections-44-f69220.svg)](./corrections-log.md)
[![Self-improving](https://img.shields.io/badge/self--improving-hook--powered-2ea44f.svg)](#self-improvement-system)

</div>

---

Biz UI Forge is an opinionated UI-engineering skill for Claude Code. It routes every request through one of **12 named modes** — each with explicit pre-read rules, structural templates, exit checklists, and reference playbooks — so output lands consistently with your codebase's conventions. The skill self-improves: user corrections flow through a hook pipeline into structured logs and promoted rules that carry the same weight as its non-negotiable rules.

- **Mode-driven.** `--fix` · `--check` · `--suggest` · `--redesign` · `--build` · `--mockup` · `--implement` · `--variant` · `--learn` · `--amplify` · `--doc` — plus inferred modes from phrasing. Each mode has a scoped role, required pre-reads, and a binary exit gate.
- **Project-aware by default.** Reads `learned-rules.md`, `corrections-log.md`, a project style guide (if present), and existing sibling components before writing anything — never reinvents conventions the host repo already has.
- **Self-improving.** A `UserPromptSubmit` hook auto-captures correction signals; Claude converts them to categorized entries, and repeated ones get promoted to `learned-rules.md`. Violating a learned rule is treated as a bug.
- **Backend-literate.** The `--amplify` mode covers AWS Amplify Gen 2 scaffolding, streaming Lambdas, JWKS auth, and standalone-amplify pnpm layouts — with a symptom → fix table for every known install/deploy/runtime error class.
- **Docs first-class.** `--doc` produces grounded ADRs, design docs, runbooks, specs, postmortems, and reports under `docs/` — with path conventions, subtype structures, and mandatory Author + Status fields.
- **Quality-gated.** Lint fix + scoped type diagnostics on every touched file before declaring done (LR-009). No exceptions. Pre-response gate walks every applicable learned rule before user-facing output.

[**→ Jump to Quick Start**](#quick-start)

---

## Table of Contents

- [Mode Flow at a Glance](#mode-flow-at-a-glance)
- [Modes](#modes)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Layout](#project-layout)
- [Self-Improvement System](#self-improvement-system)
  - [How Corrections Flow](#how-corrections-flow)
  - [Promotion Criteria](#promotion-criteria)
  - [Managing Rules](#managing-rules)
- [Top Learned Rules](#top-learned-rules)
- [Quality Gates](#quality-gates)
- [Writing Style](#writing-style)
- [Stats](#stats)
- [References & Playbooks](#references--playbooks)
- [Author](#author)

---

## Mode Flow at a Glance

```
                           ┌──────────────────────────────┐
                           │   User input + optional flag  │
                           └───────────────┬───────────────┘
                                           │
                  ┌────────────────────────┴────────────────────────┐
                  │            Mode chooser + inference             │
                  │  (flag wins · else phrasing heuristics)         │
                  └────────────────────────┬────────────────────────┘
                                           │
          ┌─────────────────┬───────────────┼───────────────┬─────────────────┐
          ▼                 ▼               ▼               ▼                 ▼
   ┌────────────┐    ┌────────────┐  ┌────────────┐  ┌────────────┐    ┌────────────┐
   │   UI-ish   │    │  Analysis  │  │   Author   │  │   Backend  │    │    Meta    │
   │ fix/build/ │    │ check/     │  │  mockup/   │  │  amplify   │    │ learn/doc  │
   │ redesign/  │    │ suggest/   │  │  variant/  │  └──────┬─────┘    └──────┬─────┘
   │ implement  │    │ audit      │  │  implement │         │                 │
   └─────┬──────┘    └─────┬──────┘  └─────┬──────┘         │                 │
         │                 │               │                │                 │
         ▼                 ▼               ▼                ▼                 ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │  Pre-read phase (learned-rules · corrections-log · target · siblings)        │
   ├──────────────────────────────────────────────────────────────────────────────┤
   │  Mode body (structural template per SKILL.md)                                │
   ├──────────────────────────────────────────────────────────────────────────────┤
   │  Pre-response gate (lint fix · scoped type diagnostics · rule walk)          │
   ├──────────────────────────────────────────────────────────────────────────────┤
   │  Exit checklist binary pass                                                  │
   └────────────────────────────┬─────────────────────────────────────────────────┘
                                ▼
                     ┌─────────────────────────┐
                     │   Output to user        │
                     │ + auto-capture hooks    │
                     │ on next user prompt     │
                     └─────────────────────────┘
```

---

## Modes

| Mode | Flag / Trigger | Acts like | Output |
| --- | --- | --- | --- |
| **fix** | `--fix` or bug + screenshot | senior frontend engineer | root cause · safe fix · regression notes |
| **check** | `--check` or "review for bugs" | QA engineer | risk-rated findings · verdict · no code |
| **suggest** | `--suggest` or "what would you improve" | senior consultant | 5–8 UI + 3–7 logic improvements · no code |
| **audit** | component path + review intent | senior reviewer | 8-section assessment + score out of 10 |
| **redesign** | component path + modernization intent | designer + engineer | direction brief + implementation |
| **build** | new page from requirements | senior frontend engineer | direction brief + implementation |
| **mockup** | requirements description | senior UI/UX designer | standalone HTML/CSS/JS concept |
| **implement** | mockup / screenshot / Figma + target | senior frontend engineer | production code across all owning files |
| **variant** | "another version" / "try a different approach" | senior UI/UX designer | new mockup variant without overwriting |
| **learn** | `--learn` | skill maintainer | `learned-rules.md` updated |
| **amplify** | `--amplify` or Amplify / ampx / Lambda / CDK intent | senior cloud engineer | scaffold · fix · extend `amplify/` + wiring |
| **doc** | `--doc` or "write an ADR / runbook / postmortem" | senior tech writer / staff engineer | markdown under `docs/<subfolder>/` with subtype structure |

Mode selection prefers the explicit flag; phrasing heuristics kick in when no flag is given. Full inference rules in [`SKILL.md`](./SKILL.md#mode-chooser).

---

## Prerequisites

- **Claude Code** — installed and available in the repo where this skill is dropped in.
- **`.claude/hooks/detect-corrections.sh`** executable in the host repo — auto-appends correction signals to `corrections-log.jsonl`. Create it the first time you add this skill to a new project.
- **Git user configured** (`git config user.name`) — required by the Doc mode's Author field.

No install step — the skill lives at `.claude/skills/biz-ui-forge/` and Claude Code picks it up automatically via the `SKILL.md` frontmatter.

---

## Quick Start

```bash
# Fix a UI bug
/biz-ui-forge --fix <component-path> button not disabled while loading

# Review a component for logic issues (no code output)
/biz-ui-forge --check <component-path>

# Get UI + logic improvement ideas (no code output)
/biz-ui-forge --suggest <component-path>

# Turn a mockup into real code
/biz-ui-forge --implement <mockup-path> into <target-component>

# Scaffold a new Lambda via Amplify Gen 2
/biz-ui-forge --amplify add a function "order-events" that streams order status

# Write an ADR or design doc
/biz-ui-forge --doc adr "<decision title>"

# Teach the skill a rule you keep enforcing
/biz-ui-forge --learn always use theme.palette.*.main, never .light
```

Every command routes through [`SKILL.md`](./SKILL.md) → reads relevant rules → produces output → runs lint + diagnostics (when code was written) → passes the exit checklist before returning.

---

## Project Layout

```
biz-ui-forge/
├── SKILL.md                      Skill definition — modes, rules, checklists (source of truth)
├── README.md                     This file
├── CHANGELOG.md                  Skill evolution history
│
├── learned-rules.md              Promoted rules (same weight as non-negotiable rules)
├── corrections-log.md            Structured correction history with root causes + fixes
├── corrections-log.jsonl         Raw hook captures — machine-readable, never edit manually
├── successes-log.md              Approaches that worked without pushback
│
├── agents/                       Mode-specific agent configurations (when used)
│
└── references/                   Deep playbooks loaded per mode
    ├── amplify-playbook.md         Amplify Gen 2 layout · ampx invocation · symptom table
    ├── implement-playbook.md       Zone map → file ownership → phased implementation
    ├── mockup-playbook.md          Mockup construction rules
    ├── mockup-html-rules.md        Standalone HTML/CSS/JS constraints
    ├── theme-rules.md              Design-system tokens · alpha usage · token precedence
    ├── theme-aware-components.md   Dark-mode-safe component patterns
    ├── review-checklist.md         Pre-submit exit gate
    ├── audit-framework.md          Audit-mode structure + scoring
    ├── design-directions.md        Direction-brief shape and examples
    ├── mui-implementation.md       MUI-specific implementation guidance
    ├── mui-prototype-mode.md       Fast prototyping within MUI
    ├── structure-match.md          Matching existing project conventions
    └── skill-evolution-protocol.md How the self-improvement loop runs
```

---

## Self-Improvement System

### How Corrections Flow

```
┌──────────────┐   hook fires   ┌──────────────────────┐
│ User message │ ─────────────▶ │ corrections-log.jsonl │  raw capture
└──────────────┘                └──────────┬───────────┘
                                           │ Claude analyzes
                                           ▼
                                ┌──────────────────────┐
                                │  corrections-log.md  │  structured + categorized
                                └──────────┬───────────┘
                                           │ count ≥ 2 · high severity · "always" / "never"
                                           ▼
                                ┌──────────────────────┐
                                │  learned-rules.md    │  promoted · enforced
                                └──────────────────────┘

         ┌────────────────────┐          ┌──────────────────────┐
         │  Clean acceptance  │ ───────▶ │   successes-log.md   │  reinforcement
         └────────────────────┘          └──────────────────────┘
```

Hook: `.claude/hooks/detect-corrections.sh` — triggered on `UserPromptSubmit`. Detects correction signals ("no", "wrong", "again", "you forgot"), appends raw text to `corrections-log.jsonl`, and injects a reminder so Claude analyzes + logs properly.

### Promotion Criteria

A correction is promoted from `corrections-log.md` to `learned-rules.md` when **any one** of these is met:

- `count >= 2` (the same class of mistake has recurred)
- **High severity** — the mistake caused significant rework
- **Explicit user instruction** — "always do X" / "never do Y"

### Managing Rules

```bash
/biz-ui-forge --learn <rule description>    # add a new rule
/biz-ui-forge --learn list                  # list all rules
/biz-ui-forge --learn remove LR-XXX         # remove by ID
/biz-ui-forge --learn review                # audit: dedup, retire stale, promote pending
```

Every rule has: ID · title · promoted-from · category · mode tags · rule statement · reason. Categories: `theme-violation` · `skipped-zone` · `skipped-child` · `skipped-state` · `logic-destroyed` · `wrong-mode` · `wrong-component` · `assumption-error` · `incomplete-phase` · `style-drift` · `framework-leak` · `other`.

---

## Top Learned Rules

Five rules with the biggest blast radius across code-producing modes:

| ID | Title | Why it matters |
| --- | --- | --- |
| **LR-009** | Mandatory quality gate — lint fix + type-check on every edit | Skipping either half lets broken imports, unused vars, and type regressions land. The gate is `AND`, not `OR`. |
| **LR-013** | Nav route checklist — update all coupled files when adding a page | Miss one and navigation 404s, permissions silently block, or type unions reject the new entity. |
| **LR-020** | Comments read like a developer, not AI | Covers `//`, `/* */`, and JSDoc. No restated signatures, no `// when set, X` prose — terse why-over-what only. |
| **LR-024** | All UI must be responsive — use design-system breakpoints | Fixed grids crush content at mobile width. Responsiveness is part of the exit checklist. |
| **LR-IC** | Icon policy — one icon library, varied families, no emoji as icons | One canonical icon system. Emoji can't be themed; string-identifier libraries keep leaking back in. |

Full list: [`learned-rules.md`](./learned-rules.md).

---

## Quality Gates

Every code-producing mode runs this gate **before** returning output to the user. Binary pass — skipping an item is a bug.

| Gate | What it does | Enforced by |
| --- | --- | --- |
| `eslint --fix <touched-files>` | Fixes formatting, import order, indentation on touched files only | LR-009 |
| Scoped type diagnostics per file | Language-server check — faster than project-wide `tsc` | LR-009 / LR-031 |
| No unused imports/vars left | Strict mode surfaces unused as build errors | LR-011 |
| No hardcoded colors/spacing | Theme tokens only | LR-005 |
| One icon library, no emoji | Canonical icon policy | LR-IC |
| Responsive at all standard breakpoints | Breakpoint objects, not fixed grids | LR-024 |
| No deep barrel imports | Import from the narrowest sub-path the package exposes | LR-032 |

---

## Writing Style

Rules of thumb applied across every mode's output:

- **No fluff preambles** — start with signal. No "In this document we will discuss..." openers.
- **Terse over cute** — one clear sentence beats a clever paragraph.
- **Cite real files** — relative path + line number, never invented paths.
- **Absolute dates** — ISO `YYYY-MM-DD` in metadata; prose may phrase ("Thursday 2026-04-24").
- **Comments only when WHY is non-obvious** — see LR-020 and LR-030.
- **Mark unknowns explicitly** — `TBD`, `PLANNED`, `NOT YET IMPLEMENTED`. Never imply completeness.

---

## Stats

| Metric | Value |
| --- | --- |
| Modes with exit checklists | 12 |
| Learned rules (enforced) | 27 |
| Structured corrections tracked | 44 |
| Reference playbooks | 13 |
| Self-improvement layers | 4 (auto-capture · structured analysis · distilled rules · success tracking) |

Last stats refresh: 2026-04-24.

---

## References & Playbooks

Mode-specific deep dives loaded on demand. See [`references/`](./references/):

- [`amplify-playbook.md`](./references/amplify-playbook.md) — Amplify Gen 2 layout, `ampx` invocation invariants, symptom → fix table, reset-to-green procedure
- [`implement-playbook.md`](./references/implement-playbook.md) — zone map construction, file-ownership tracing, phased implementation
- [`mockup-playbook.md`](./references/mockup-playbook.md) — mockup design principles and construction rules
- [`theme-rules.md`](./references/theme-rules.md) — design-system theme tokens, alpha usage, token precedence
- [`review-checklist.md`](./references/review-checklist.md) — the pre-submit exit gate

---

## Author

**Pavan Kumar Mistry**

A personal Claude Code skill authored and maintained by Pavan. It is portable — drop the `biz-ui-forge/` folder into any project's `.claude/skills/` directory and it works. Free to fork, adapt, and tune to your own stack.
