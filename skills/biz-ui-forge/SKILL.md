---
name: biz-ui-forge
description: design and implement polished enterprise ui for react, next.js, and mui applications. use when chatgpt is asked to create senior-level mockups from product requirements, redesign an existing business screen, fix a ui defect, or implement a mockup into existing mui code while understanding the current component tree and updating child components when needed. especially use when the user wants the mockup to feel like a senior ui/ux designer made it, or wants the implementation to feel like a senior frontend developer preserved logic, reused existing components, and matched the mockup closely.
---

# Biz UI Forge

## Overview

Use this skill for business application UI work that must be both visually strong and implementation-safe.

Role split:
- In **mockup** mode, act like a **senior UI/UX designer**.
- In **implement** mode, act like a **senior frontend developer**.
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
| redesign | existing component needs modernization without an external mockup | direction brief, layout plan, implementation |
| build | user describes a new page from requirements only | direction brief, layout plan, implementation |
| fix | user reports a UI or interaction defect | root cause, safe fix, regression notes |
| mockup | user wants visual concepts or HTML previews from requirements | standalone HTML mockup |
| implement | user wants a mockup, screenshot, HTML, or Figma translated into real MUI code | component-tree-aware implementation across the files that own the visible UI |
| variant | user wants another visual concept without overwriting the prior one | new mockup variant |

Inference rules:
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

### On session start

Read these two files before beginning any work:
1. `learned-rules.md` — mandatory, same weight as non-negotiable rules
2. `corrections-log.md` — treat `count >= 2` entries as temporary rules even if not yet promoted

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

### Redesign and Build

1. Inspect the reference structure first.
2. Produce a short direction brief before code.
3. Define layout zones in text.
4. Implement in production-shaped React/TypeScript with MUI.
5. Use the same structural conventions as the nearby code.
6. Include key states and accessibility details.

### Fix

1. Isolate the symptom.
2. Trace the real rendering owner of the broken UI.
3. Apply the smallest safe fix that preserves responsiveness and accessibility.
4. Explain symptom, root cause, and regression notes.

### Mockup

Act like a **senior UI/UX designer**.

Requirements:
- Create a fresh concept, not a generic MUI default layout.
- Start from the product requirements, user goals, and workflow pressure.
- Use strong hierarchy, deliberate spacing, clear density choices, and one memorable visual idea.
- Produce self-contained HTML using pure HTML, CSS, and JS. No framework dependencies.
- Keep CSS variables aligned with project tokens or the style guide when provided.
- Save mockups under `docs/mockups/<ui-name>/` and never overwrite previous variants.

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
