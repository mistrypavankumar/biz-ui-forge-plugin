# Biz UI Forge

Enterprise UI skill for Claude Code — design, implement, review, and fix React/MUI interfaces.

## Quick Start

```
/biz-ui-forge --fix <component-path> <description>     # fix a UI bug
/biz-ui-forge --check <component-path>                  # logic review (no code changes)
/biz-ui-forge --suggest <component-path>                # quick UI improvement ideas
/biz-ui-forge <mockup/screenshot> implement into <path> # mockup → production MUI
/biz-ui-forge --learn <rule>                            # teach it a new rule
```

## Modes

| Mode | Flag / Trigger | Output |
|---|---|---|
| **fix** | `--fix` or bug description | root cause + safe fix + regression notes |
| **check** | `--check` | risk-rated findings report (no code) |
| **suggest** | `--suggest` | prioritized improvement list (no code) |
| **audit** | component path + review intent | scored assessment report (no code) |
| **implement** | mockup/screenshot + component path | MUI code across all owning files |
| **mockup** | requirements description | standalone HTML/CSS/JS mockup |
| **redesign** | component path + modernization intent | direction brief + implementation |
| **build** | new page from requirements | direction brief + implementation |
| **variant** | "another version" / "try a different approach" | new mockup variant |
| **learn** | `--learn` | manage learned rules |

## Self-Improvement System

The skill tracks mistakes and gets better over time:

```
Hook (auto-capture) → corrections-log.jsonl (raw)
                     → corrections-log.md (structured, categorized)
                     → learned-rules.md (promoted, enforced)
                     → successes-log.md (what worked)
```

- Corrections auto-detected via shell hook on `UserPromptSubmit`
- Rules promoted when count >= 2, high severity, or explicit instruction
- Pre-response gate checks all applicable rules before presenting output

### Managing Rules

```
/biz-ui-forge --learn <rule description>    # add a rule
/biz-ui-forge --learn list                  # show all rules
/biz-ui-forge --learn remove LR-XXX         # remove a rule
/biz-ui-forge --learn review                # audit: dedup, retire stale, promote pending
```

## Files

```
biz-ui-forge/
  SKILL.md              # main skill definition (modes, rules, checklists)
  learned-rules.md      # enforced rules (same weight as non-negotiable rules)
  corrections-log.md    # structured correction history with root causes
  corrections-log.jsonl # raw hook captures (machine-readable, don't edit)
  successes-log.md      # approaches that worked without corrections
  references/           # mode-specific playbooks and checklists
    implement-playbook.md
    mockup-playbook.md
    theme-rules.md
    review-checklist.md
    audit-framework.md
    ...8 more reference docs
```

## Key Rules (top 5 most impactful)

1. **LR-009** — run eslint + type-check on touched files before declaring done
2. **LR-IC** — react-icons only, no Iconify strings, no emoji, varied families
3. **LR-002** — pixel-match every mockup detail (text casing, icons, spacing, variants)
4. **LR-007** — SSRM tables use `invalidate` + `router.refresh()`, not `refetchQueries`
5. **LR-021** — extract the largest reusable boundary, not the smallest visible duplication

## Current Stats

- **14** learned rules (consolidated from 20, all mode-tagged)
- **7** structured corrections tracked
- **11** raw hook captures since 2026-04-01
- **10** modes with exit checklists
- **12** reference documents
