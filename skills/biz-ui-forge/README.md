# Biz UI Forge

Enterprise UI skill for Claude Code — design, implement, review, and fix React/MUI interfaces.

## Quick Start

```
/biz-ui-forge --fix <component-path> <description>     # fix a UI bug
/biz-ui-forge --check <component-path>                  # logic review (no code changes)
/biz-ui-forge --suggest <component-path>                # quick UI improvement ideas
/biz-ui-forge <mockup/screenshot> implement into <path> # mockup → production MUI
/biz-ui-forge --amplify <ask>                           # any Amplify Gen 2 backend task
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
| **amplify** | `--amplify` or any Amplify Gen 2 / ampx / Lambda / CDK / Function URL task | scaffold, fix, extend, debug Amplify backend across `amplify/` + root plumbing |
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
  README.md             # this file
  CHANGELOG.md          # skill evolution history
  learned-rules.md      # enforced rules (same weight as non-negotiable rules)
  corrections-log.md    # structured correction history with root causes
  corrections-log.jsonl # raw hook captures (machine-readable, don't edit)
  successes-log.md      # approaches that worked without corrections
  references/           # mode-specific playbooks and checklists
    amplify-playbook.md         # Amplify Gen 2 layout, ampx invocation, symptom table
    implement-playbook.md       # zone map → file ownership → phased implementation
    mockup-playbook.md          # mockup construction rules
    mockup-html-rules.md        # standalone HTML/CSS constraints for mockups
    theme-rules.md              # MUI theme tokens, alpha values, .main vs .light
    theme-aware-components.md   # dark-mode safe component patterns
    review-checklist.md         # pre-submit exit gate
    audit-framework.md          # audit-mode structure and scoring
    design-directions.md        # direction-brief shape and examples
    mui-implementation.md       # MUI-specific implementation guidance
    mui-prototype-mode.md       # fast prototyping within MUI
    structure-match.md          # matching project conventions
    skill-evolution-protocol.md # how the self-improvement loop runs
```

## Key Rules (top 5 most impactful)

1. **LR-009** — run eslint + `getDiagnostics` on touched files before declaring done
2. **LR-020** — comments read like a developer, not AI — covers `//`, `/* */`, AND JSDoc blocks
3. **LR-IC** — react-icons only, no Iconify strings, no emoji, varied families
4. **LR-013** — nav route checklist: 9 files to update when adding a page, or permissions silently break
5. **LR-024** — all UI responsive via MUI breakpoints — fixed grids like `repeat(4,1fr)` overflow on mobile

## Current Stats

- **19** learned rules, all mode-tagged
- **15** structured corrections tracked (including 3 amplify-mode entries, AMP-001..003)
- **28** raw hook captures since 2026-04-01
- **11** modes with exit checklists (added `amplify` mode 2026-04-17)
- **13** reference documents (added `amplify-playbook.md` for Amplify Gen 2 layout)
