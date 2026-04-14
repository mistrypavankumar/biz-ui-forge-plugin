---
name: biz-ui-forge
description: design and implement polished enterprise ui for react, next.js, and mui applications. use when chatgpt is asked to create senior-level mockups from product requirements, redesign an existing business screen, fix a ui defect, or implement a mockup into existing mui code while understanding the current component tree and updating child components when needed. especially use when the user wants the mockup to feel like a senior ui/ux designer made it, or wants the implementation to feel like a senior frontend developer preserved logic, reused existing components, and matched the mockup closely. also use when user wants quick ui improvement suggestions (--suggest) or a quality checklist pass/fail gate (--check) on existing components.
---

# Biz UI Forge

## Overview

Use this skill for business application UI work that must be both visually strong and implementation-safe.

Role split:
- In **mockup** mode, act like a **senior UI/UX designer**.
- In **implement** mode, act like a **senior frontend developer**.
- In **suggest** mode, act like a **senior UI consultant** giving quick actionable improvements.
- In **check** mode, act like a **QA engineer** running a pass/fail quality gate.
- In **audit**, **redesign**, and **fix** modes, combine product judgment with safe production-minded frontend execution.

Read project reality before changing design. Do not redesign from assumptions.

## Mandatory: Use Sequential Thinking

**Before every non-trivial decision, use `mcp__modelcontextprotocol-servers-sequentialthinking__sequentialthinking` to reason through it step by step.** This is not optional — it prevents skipping steps, partial implementations, and rushed decisions.

Use sequential thinking for:
1. **Mode selection** — think through which mode fits the request before committing.
2. **Zone map construction** — reason through each visible zone, what it contains, and whether it's app-shell or page-specific.
3. **File ownership tracing** — think through which component file owns each zone before building the file map.
4. **Phasing decisions** — reason through zone count, priority ordering, and phase boundaries.
5. **Per-zone implementation** — before writing code for each zone, think through: what the mockup shows, what the existing code does, what MUI components to use, what theme tokens map to the CSS variables, and what props/data are needed.
6. **Cross-file verification** — after implementation, think through whether all zones are accounted for, props align, and states are covered.

Do not skip sequential thinking to save time. The quality of implementation depends on thinking before coding.

## Mode chooser

Choose exactly one mode.

| Mode | Use when | Output |
| --- | --- | --- |
| audit | user wants assessment only | report only, no code |
| suggest | user wants quick, actionable UI improvement ideas (`--suggest`) | prioritized suggestion list with rationale, no code |
| check | user wants logic correctness review with risk levels (`--check`) | risk-rated findings with suggested fixes, no code changes |
| redesign | existing component needs modernization without an external mockup | direction brief, layout plan, implementation |
| build | user describes a new page from requirements only | direction brief, layout plan, implementation |
| fix | user reports a UI or interaction defect | root cause, safe fix, regression notes |
| mockup | user wants visual concepts or HTML previews from requirements | standalone HTML mockup |
| implement | user wants a mockup, screenshot, HTML, or Figma translated into real MUI code | component-tree-aware implementation across the files that own the visible UI |
| variant | user wants another visual concept without overwriting the prior one | new mockup variant |
| learn | user wants to add, list, or remove learned rules (`--learn`) | updated `learned-rules.md` |

Inference rules:
- `--learn` flag or "add rule" / "learn this" / "new rule" / "remember this" means **learn**.
- `--suggest` flag or "suggest improvements" / "what would you improve" means **suggest**.
- `--check` flag or "check logic" / "is this correct" / "review for bugs" means **check**.
- Existing component path or pasted code plus review-only intent means **audit**.
- Existing component path or pasted code plus modernization intent means **redesign**.
- Screenshot plus bug intent means **fix**.
- Requirements-first visual exploration means **mockup** unless the user explicitly asks for production code.
- Any request to turn a mockup, screenshot, HTML, or Figma design into MUI/React means **implement**.
- If a visual zone belongs to a child component, table row, card, modal, tab panel, or sibling module, still stay in **implement** and update the necessary files. Do not force a parent-only implementation.

## Non-negotiable rules

1. Read only the files that matter: target component, immediate child components that own visible zones, relevant types, theme files, and any project style guide.
2. Reuse existing project components before creating new ones.
3. Preserve business logic, data fetching, state management, handlers, and data contracts unless the user explicitly asks to change them.
4. Use semantic MUI theme tokens. Do not hardcode colors, spacing, typography, shadows, or radii when implementing real code.
5. Match the mockup or visual reference closely. Do not drop visible elements, states, or hierarchy.
6. Follow the local codebase structure: import grouping, hook order, naming, layout primitives, and export style.
7. Treat dark mode, hover, focus, loading, empty, error, and disabled states as required quality checks.
8. When a mockup cannot be matched in the parent file alone, inspect and update the child components that render the missing zones.

## Self-Improvement: Hook-Powered Correction Tracking

This skill automatically tracks mistakes and evolves its rules over time using a three-layer system.

### Layer 1: Auto-Capture (Hook)

A `UserPromptSubmit` hook (`.claude/hooks/detect-corrections.sh`) monitors every user message for correction signals (e.g., "no", "not that", "wrong", "you forgot", "again"). When detected:
- Raw correction text is appended to `corrections-log.jsonl` (machine-readable, never edit manually)
- A context reminder is injected telling Claude to analyze and log the correction properly

### Layer 2: Structured Analysis (Claude)

When the hook fires (or when you recognize a correction even without the hook):
1. Read `corrections-log.md` — check if the same root cause already exists
2. If match: increment `count`, update date
3. If new: add a structured entry at the top with root cause category
4. Categories: `theme-violation` · `skipped-zone` · `skipped-child` · `skipped-state` · `logic-destroyed` · `wrong-mode` · `wrong-component` · `assumption-error` · `incomplete-phase` · `style-drift` · `framework-leak` · `other`

### Layer 3: Learned Rules (Distilled)

`learned-rules.md` contains promoted corrections — **these carry the same weight as non-negotiable rules**. Violating a learned rule is treated as a bug.

**Promotion criteria** (any one is sufficient):
- `count >= 2` in corrections-log.md
- High severity (caused significant rework)
- User explicitly says "always do X" or "never do Y"

**Promotion process** (triggered by user saying "review corrections" or "improve the skill"):
1. Review all `active` entries in `corrections-log.md`
2. Propose specific rules for `learned-rules.md` — get user approval
3. Add approved rules, mark corrections as `[PROMOTED]`

### Layer 4: Success Tracking

`successes-log.md` tracks approaches the user approved without pushback. When the user accepts output on the first try (no corrections, no "but"), log a short entry:

```
### S-XXX — Short title
- **Date**: YYYY-MM-DD
- **Mode**: fix | implement | mockup | etc.
- **What worked**: Brief description of the approach
- **Why it worked**: What made this the right call
```

This reinforces good patterns. Review alongside corrections during `--learn review`.

### On session start

Read these files before beginning any work:
1. `learned-rules.md` — mandatory, same weight as non-negotiable rules
2. `corrections-log.md` — treat `count >= 2` entries as temporary rules even if not yet promoted
3. `successes-log.md` — if it exists, note what approaches worked well

### Pre-response self-check

Before presenting any output to the user, scan all applicable learned rules and verify zero violations. This is a hard gate — not optional.

1. Filter `learned-rules.md` to rules tagged with the current mode (or `all` modes)
2. For each applicable rule, verify the output doesn't violate it
3. If a violation is found, fix it before responding — don't present and apologize later
4. Pay extra attention to rules with `count >= 2` in corrections-log.md

## Read first

When these files exist, prioritize them in this order:
1. **`learned-rules.md`** — mandatory, same authority as non-negotiable rules.
2. **`corrections-log.md`** — check for active patterns before starting.
3. The target component or page.
4. Immediate imported child components that render visible UI.
5. Adjacent types, query fragments, and constants used by the target UI.
6. `docs/design/global-style-guide.md`.
7. Theme files and component overrides.

Do not read the whole repo unless the user explicitly asks for broad exploration.

## Project-aware implementation

Before adding new UI, scan for reusable components in the project's shared UI folders. Prefer existing layout shells, cards, form fields, table wrappers, modals, tabs, banners, loaders, and icon wrappers.

When implementing code, also read:
- `references/implement-playbook.md`
- `references/theme-rules.md`
- `references/mockup-playbook.md` for mockup work
- `references/review-checklist.md` before finalizing

## Mode instructions

### Audit

Report only. No implementation code.

Use this structure:
1. Context summary
2. What works
3. What feels weak or generic
4. UX risks
5. Visual hierarchy issues
6. Interaction/state issues
7. Prioritized recommendations
8. Score out of 10

**Exit checklist:**
- [ ] All 8 report sections covered
- [ ] Score provided
- [ ] Recommendations prioritized
- [ ] No code output

### Suggest

Quick, actionable improvement ideas. No code output.

1. Read the target component and its immediate children.
2. Read `docs/design/global-style-guide.md` and theme files for context.
3. Produce a prioritized list of **5–10 concrete suggestions**, each with:
   - **What**: one-line description of the change
   - **Why**: the UX or visual problem it solves
   - **How**: brief description of the MUI approach (component, token, pattern)
   - **Impact**: low / medium / high
4. Group suggestions by category: hierarchy, density, color/contrast, interaction states, accessibility, consistency.
5. Do not produce code. The user decides which suggestions to pursue.

**Exit checklist:**
- [ ] 5–10 suggestions provided
- [ ] Each has What / Why / How / Impact
- [ ] Grouped by category
- [ ] No code output

### Check

Logic correctness review. No code changes — report only with risk levels and suggested fixes.

Read the target component, its children, hooks, handlers, data fetching, state management, and type definitions. Check whether the logic is correct, safe, and handles edge cases.

**What to check:**

1. **Data flow** — props drilled correctly, no stale closures, no missing dependencies in `useEffect`/`useMemo`/`useCallback`
2. **State management** — correct initial state, no race conditions, no redundant state that can derive from props/other state
3. **Conditional rendering** — guards handle `null`/`undefined`/empty arrays, no flash of wrong UI
4. **Event handlers** — correct arguments, no missing `preventDefault`, no unintended re-renders from inline arrow functions in hot paths
5. **API/GraphQL integration** — loading/error/empty states handled, no missing refetch after mutation, no stale cache reads
6. **Type safety** — no `as any` casts hiding real issues, optional chaining where needed, discriminated unions handled exhaustively
7. **Side effects** — cleanup in `useEffect`, no memory leaks from subscriptions/timers, no effects running on every render unnecessarily
8. **Permissions/auth** — permission checks present where needed, no UI that shows actions the user can't perform
9. **Edge cases** — zero items, single item, maximum items, rapid clicks, concurrent requests, network failure
10. **Business logic** — status transitions correct, calculations accurate, filters/sorts match expected behavior

**Risk levels:**
- **CRITICAL** — will cause crash, data loss, or security issue
- **HIGH** — incorrect behavior visible to users, wrong data displayed or submitted
- **MEDIUM** — works most of the time but fails on edge cases or under specific conditions
- **LOW** — code smell or minor issue unlikely to cause visible problems

**Output format per finding:**
```
[CRITICAL] Missing null guard on viewData.items — crash when entity has no items
  → Line: 82
  → Fix: Add optional chaining `viewData?.items?.map(...)` or early return if !viewData

[HIGH] Mutation onCompleted doesn't refetch list query — stale data after save
  → Line: 145
  → Fix: Add `refetchQueries: [{ query: GET_SALES_ORDERS }]` to mutation options

[MEDIUM] useEffect missing `filters` dependency — filter changes won't trigger re-fetch
  → Line: 63
  → Fix: Add `filters` to dependency array, or move filter logic into the effect

[LOW] Inline arrow in onClick creates new reference each render — minor perf in large list
  → Line: 201
  → Fix: Extract handler with useCallback if list > 50 items
```

**Summary format:**
```
Result: 2 CRITICAL · 1 HIGH · 3 MEDIUM · 1 LOW
Verdict: BLOCKED — fix CRITICAL and HIGH before shipping
```

Verdicts:
- **CLEAR** — no CRITICAL or HIGH findings
- **CAUTION** — no CRITICAL, but has HIGH findings worth reviewing
- **BLOCKED** — has CRITICAL findings that must be fixed

**Exit checklist:**
- [ ] All 10 check categories evaluated
- [ ] Each finding has risk level, line number, and fix
- [ ] Summary with verdict provided
- [ ] No code changes made

### Redesign and Build

1. Inspect the reference structure first.
2. Produce a short direction brief before code.
3. Define layout zones in text.
4. Implement in production-shaped React/TypeScript with MUI.
5. Use the same structural conventions as the nearby code.
6. Include key states and accessibility details.

**Exit checklist:**
- [ ] Direction brief provided before code
- [ ] Layout zones defined
- [ ] Theme tokens used (no hardcoded values)
- [ ] Key states covered (loading, empty, error, hover, disabled)
- [ ] Existing project components reused
- [ ] `eslint --fix` ran on touched files
- [ ] Type-check passed on touched files

### Fix

1. Isolate the symptom.
2. Trace the real rendering owner of the broken UI.
3. Apply the smallest safe fix that preserves responsiveness and accessibility.
4. Explain symptom, root cause, and regression notes.

**Exit checklist:**
- [ ] Root cause identified and explained
- [ ] Fix applied to the correct file (not just the parent)
- [ ] Regression notes provided
- [ ] No unused imports/variables left in touched files
- [ ] `eslint --fix` ran on touched files
- [ ] Type-check passed on touched files

### Mockup

Act like a **senior UI/UX designer**.

Requirements:
- Create a fresh concept, not a generic MUI default layout.
- Start from the product requirements, user goals, and workflow pressure.
- Use strong hierarchy, deliberate spacing, clear density choices, and one memorable visual idea.
- Produce self-contained HTML using pure HTML, CSS, and JS. No framework dependencies.
- Keep CSS variables aligned with project tokens or the style guide when provided.
- Save mockups under `docs/mockups/<ui-name>/` and never overwrite previous variants.

**Exit checklist:**
- [ ] Saved under `docs/mockups/<ui-name>/`
- [ ] No emoji icons — SVG or react-icons paths only
- [ ] CSS vars match project tokens / style guide
- [ ] Dark mode variant considered
- [ ] Loading, empty, error states shown or noted
- [ ] Previous variants not overwritten

### Implement

Act like a **senior frontend developer**.

Use `references/implement-playbook.md`.

Core behavior:
- Treat the visual reference as the visual source of truth.
- Treat the existing codebase as the structural source of truth.
- **Skip app-shell zones** (sidebar, topbar, breadcrumb, global nav) — these already exist in the layout. Focus only on page-specific content.
- **Phase large mockups** — if the mockup has 7+ page-specific zones, split into phases (structure → secondary content → overlays). Complete each phase fully. Emit a zone progress checklist after each phase so follow-up runs can resume.
- **Check for prior progress** — before starting, look for `docs/design/[feature]-zone-progress.md`. If it exists, resume from the first pending zone instead of starting over.
- Inspect the parent component and the child components that actually render the visible zones.
- Update any child component, sibling presentational module, shared cell renderer, card, modal, or tab panel when that file owns part of the design.
- Keep logic intact while replacing layout and styling.
- If a child component needs a new prop to support the mockup, update both the child props and the parent call site.
- If a visual requirement spans multiple files, implement across those files in one coordinated pass instead of stopping at the parent.
- If required data is missing from the current types or query, explicitly flag the gap instead of inventing data.
- **Complete each zone fully before moving to the next** — a half-implemented zone is worse than a missing one.

**Exit checklist:**
- [ ] All page-specific zones accounted for (app-shell skipped)
- [ ] Child components updated where they own visible zones
- [ ] Mockup pixel-matched — text casing, icons, chips, spacing, variants
- [ ] No hardcoded colors/spacing — theme tokens only
- [ ] react-icons used (zero Iconify strings)
- [ ] Loading, empty, error states handled
- [ ] No unused imports/variables in touched files
- [ ] `eslint --fix` ran on touched files
- [ ] Type-check passed on touched files
- [ ] Zone progress checklist emitted (if phased)

### Learn

Manage learned rules directly. No code changes — only updates `learned-rules.md`.

**Sub-commands** (passed as arguments after `--learn`):

| Usage | Action |
| --- | --- |
| `--learn <rule description>` | Add a new learned rule |
| `--learn list` | List all current learned rules with their IDs |
| `--learn remove <LR-ID>` | Remove a learned rule by ID |
| `--learn review` | Audit rules — consolidate duplicates, retire stale ones, promote pending corrections |

**Adding a rule** (`--learn <rule description>`):

1. Read `learned-rules.md` to find the current highest `LR-XXX` ID.
2. Determine the next ID (e.g., if `LR-006` is the highest, use `LR-007`).
3. Classify the rule into a category: `theme-violation` · `skipped-zone` · `skipped-child` · `skipped-state` · `logic-destroyed` · `wrong-mode` · `wrong-component` · `assumption-error` · `incomplete-phase` · `style-drift` · `framework-leak` · `other`.
4. Assign mode tags: which modes does this rule apply to? Use `all` if it applies everywhere, or a comma-separated list like `implement, mockup`.
5. Write the new rule at the top of the rules list (after the header), following this format:
   ```
   ### LR-XXX — Short title
   - **Promoted from**: User explicit instruction (YYYY-MM-DD)
   - **Category**: <category>
   - **Modes**: all | <comma-separated modes>
   - **Rule**: <clear, actionable rule statement>
   - **Why**: <reason the rule exists — what goes wrong without it>
   ```
6. Confirm to the user what was added, showing the ID and title.

**Listing rules** (`--learn list`):

1. Read `learned-rules.md`.
2. Display a concise table of all rules: `| ID | Title | Category | Modes |`.

**Removing a rule** (`--learn remove LR-XXX`):

1. Read `learned-rules.md`.
2. Find the rule block matching the given ID.
3. Remove the entire `### LR-XXX` block (heading through to the next heading or end of file).
4. Confirm removal to the user.

**Reviewing rules** (`--learn review`):

1. Read `learned-rules.md`, `corrections-log.md`, and `successes-log.md`.
2. Check for:
   - **Duplicates**: rules that overlap in intent — propose merging
   - **Stale rules**: rules about patterns no longer in the codebase — propose retiring
   - **Pending promotions**: corrections with `count >= 2` not yet in learned-rules — propose promoting
   - **Missing mode tags**: rules without a `Modes` field — propose adding
   - **Success reinforcement**: approaches from successes-log that could become positive rules
3. Present findings as a checklist. Apply only what the user approves.

## Deliverable order

Use this order unless the mode says otherwise:
1. Context and chosen direction
2. Zone map or layout architecture
3. Audit or implementation
4. Final notes and verification summary

## Constraints

- Do not invent hidden project conventions.
- Do not flatten distinctive mockup structure into generic stacked cards unless the mockup truly shows that.
- Do not silently ignore child-owned UI while claiming the mockup was implemented.
- Do not rewrite business logic just to make styling easier.
