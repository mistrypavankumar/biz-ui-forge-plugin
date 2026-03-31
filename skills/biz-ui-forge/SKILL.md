---
name: biz-ui-forge
description: modern business ui design skill for auditing, redesigning, building, fixing, and prototyping enterprise interfaces. use when asked to review a business ui, make an existing page feel less generic, create a new operational screen, produce html mockups, or generate a single-file mui prototype that maps closely to production next.js and mui code.
---

# Biz UI Forge

## Overview

Use this skill to turn business application UI work into a structured design workflow instead of ad hoc component edits. It supports audit-only reviews, full redesigns, greenfield builds, bug fixes, static HTML mockups, and a dedicated single-file MUI prototype mode for users who want production-shaped output without introducing many new files.

Read project reality before proposing design changes. Do not redesign from assumptions.

## Operating Modes

Choose exactly one mode per request.

| Mode | Trigger | Output |
| --- | --- | --- |
| audit | user asks to assess a component without changing it | report only, no code |
| redesign | existing component needs modernization or distinctiveness | audit, direction brief, architecture, implementation |
| build | user describes a new page or workflow | direction brief, architecture, implementation |
| fix | user reports a visual or logic bug, or shares a screenshot | root cause, safe fix, regression notes |
| mockup | user wants quick visual options or html concepts | standalone html preview files |
| mui-prototype | user wants mockup fidelity but in real mui/react form | single tsx file with inline mock data |
| variant | user wants another concept iteration | new mockup or prototype variant without overwriting previous output |

Inference rules:
- Existing component path or pasted component code plus change intent means redesign.
- Existing component path or pasted code with review-only intent means audit.
- Screenshot plus bug intent means fix.
- Requests for options, concepts, or visual exploration mean mockup unless the user explicitly wants MUI.
- Requests for "same idea but using MUI", "single TSX", "portable into app", or "closer to production" mean mui-prototype.

## Read First

Always read only the files that matter for the target component.

1. The component file or files provided.
2. Key imports that affect layout, child structure, or data loading.
3. Adjacent types files that define the data shape.
4. Theme files and design tokens used by the project.
5. `.claude/lessons-learned.md` if present, to avoid repeating past regressions.

Do not read the entire codebase. Focus on structure, layout decisions, visual patterns, state handling, and data communication.

## Discover Project Theme

Before producing any code output, discover the host project's theme system. Search for these common patterns:

1. **Theme config files** — search for files matching: `theme-config.*`, `theme.*`, `palette.*`, `colors.*`, `tokens.*` in common locations (`src/theme/`, `src/styles/`, `packages/ui/src/theme/`, `src/lib/theme/`).
2. **Theme overrides** — search for `theme-overrides.*`, `createTheme`, `extendTheme`.
3. **Typography config** — search for `typography.*` in the theme directory.
4. **Shadow/elevation tokens** — search for `shadows.*`, `custom-shadows.*`.
5. **Spacing/dimension tokens** — search for `dimensions.*`, `spacing.*`.
6. **Design tokens** — search for CSS custom property definitions or design token files.

Read whatever theme files exist. Extract:
- Available palette colors and their semantic meanings
- Light/dark mode support and how mode switching works
- Typography variants (standard and custom)
- Shadow/elevation tokens
- Spacing tokens
- CSS variable configuration

Use the discovered project tokens. Do not hardcode colors, spacing, typography, shadows, or radii when the request is for real implementation or MUI prototype work.

## Theme-Aware Components (Mandatory)

Read `references/theme-aware-components.md` before producing any code output. This is enforced across **all code-producing modes** (redesign, build, fix, mui-prototype).

Key rules:
- **Every component must render correctly in both light and dark mode** (if the project supports it).
- Use semantic palette tokens (`text.primary`, `background.paper`, `success.main`), never hex values.
- Use `theme.vars.palette` (or the project's equivalent) for dynamic/alpha styles.
- Use the project's actual primary color — do not assume a default.
- Backgrounds: use the project's surface hierarchy tokens.
- Shadows: use the project's shadow tokens.
- Interactive states: use the project's action tokens.
- Run the dark mode verification checklist from the reference before finalizing.

Failure to use theme tokens is a blocking issue — fix before delivering.

## Mode Workflows

### Audit

Read `references/audit-framework.md`.

Output the audit only. Do not include implementation code. Preserve the report headings and scoring format from the reference.

### Redesign and Build

1. **Analyze the reference structure first.** Read `references/structure-match.md`. Read the target file (for redesign) or a similar existing component (for build). Extract the structural blueprint: directive, import order, type location/naming, component signature, hook order, state approach, layout primitives, sub-component pattern, loading/error/empty handling, export style.
2. Read `references/design-directions.md`.
3. Choose one direction only. Do not blend directions.
4. Produce the direction brief before any code.
5. Define layout zones in text before coding.
6. Read `references/mui-implementation.md` before implementation.
7. Default to production-grade React and TypeScript using MUI patterns that map well to Next.js App Router work.
8. **Write code that follows the structural blueprint** — same import grouping, same type pattern, same hook order, same layout primitives. The output must look like it belongs in the same codebase.
9. Include all important states: loading, empty, error, hover, focus, active, disabled.
10. If the reference has bad patterns (hardcoded colors, missing states), silently improve them while keeping the structural shape.

### Fix

1. **Analyze the file's structure first.** Read `references/structure-match.md`. Extract the structural blueprint from the file being fixed: directive, import order, type patterns, component signature, hook order, state approach, layout primitives, sub-component style.
2. Isolate the issue.
3. If an image is provided, inspect the image first and use it as the visual source of truth.
4. For UI bugs, trace layout, stacking, responsive bounds, specificity, overflow, and focus behavior.
5. For logic bugs, trace props, async flow, derived state, and event handling.
6. **Write the fix following the file's existing conventions** — same indentation, naming style, import patterns, hook order. Do not restructure or reorganize unless the fix requires it.
7. Implement the safest fix that preserves responsiveness and accessibility.
8. Document symptom, root cause, and safe regression notes.
9. Update `.claude/lessons-learned.md` when the project contains it or when the user asks for persistent lessons.

### Mockup

Read `references/mockup-html-rules.md`.

This mode is intentionally HTML-first and MUI-shaped rather than true MUI. Use it for fast visual exploration and instant preview.

Rules:
- Output self-contained HTML files.
- Default to one best-bet concept unless the user explicitly asks for multiple concepts.
- When generating multiple concepts, vary layout paradigm, data density, action placement, and visual weight.
- Save to `docs/mockups/<ui-name>/` with sequential concept naming.
- For `variant`, never overwrite prior concepts.

### MUI Prototype

Read both `references/mui-implementation.md` and `references/mui-prototype-mode.md`.

Use this mode when the user wants prototype speed but also wants the result to look and feel like real MUI application code.

Rules:
- Produce a single `.tsx` file by default.
- Keep mock data, helper functions, and small local subcomponents in the same file.
- Prefer only imports that are already common in the host app: `@mui/material`, existing icon wrapper, and existing project utilities.
- Do not add new packages unless the user explicitly asks and the project clearly already uses them.
- If icons are needed, prefer existing project icon wrappers or inline SVG. Use `@mui/icons-material` only when the app already includes it.
- Keep the output portable into a Next.js route or component file.

## Deliverable Order

Use this order unless the mode explicitly says otherwise:

1. Context and direction.
2. Layout architecture.
3. Implementation or audit output.
4. Design notes, fix notes, or next-step handoff.

Mode-specific notes:
- Audit stops after the report and scores.
- Fix swaps direction with root cause analysis.
- Mockup summarizes the saved concepts and their differences.
- MUI prototype explains the single-file choices and how to split it later if needed.

## Interaction and Quality Bar

Across all non-audit modes:
- Avoid generic default MUI layouts.
- Use clear hierarchy for page title, section title, labels, values, metrics, and actions.
- Use semantic colors for state, not primary everywhere.
- Avoid divider-heavy layouts when surface banding or whitespace is clearer.
- Use visible hover and focus states.
- Ensure icon-only buttons have accessible labels.
- Ensure destructive actions have confirmation and recovery paths.
- Never use placeholder-only labels in forms.

## Output Expectations

### For audit
- Report only.
- Use the exact headings from the audit framework.
- Include the score line.

### For redesign and build
- Full React and TypeScript code.
- MUI-oriented layout primitives and theme usage.
- Production-grade component structure.

### For fix
- Concrete code changes.
- Clear explanation of why the fix is safe.

### For mockup
- HTML files that can be opened directly in a browser.
- Tailwind CDN only, per the mockup reference.

### For mui-prototype
- One TSX file unless the user explicitly asks for a multi-file extraction.
- Inline mock data is allowed and expected.
- Local helper renderers are allowed in the same file.
- Minimal dependencies.

## Single-File MUI Prototype Guidance

A single-file MUI prototype is acceptable when the goal is speed, reviewability, and production adjacency. Keep all of these in the same file when useful:
- mock dataset
- section config arrays
- local state
- tiny presentational helpers
- small dialog or drawer subcomponents

Split into multiple files only when the user asks for production extraction or when a single file would materially reduce clarity.

## Constraints

- Read relevant source files first.
- Prefer server-shaped data flow and production-safe architecture when writing real implementation code.
- Use tokens and references from the host project whenever they are available.
- Do not invent missing data shape details when type files are present.
- Do not silently blend mockup HTML rules into MUI prototype mode; keep those modes distinct.
- Do not overwrite prior variants.

## References

- `references/audit-framework.md`
- `references/design-directions.md`
- `references/mockup-html-rules.md`
- `references/mui-implementation.md`
- `references/mui-prototype-mode.md`
- `references/theme-aware-components.md`
- `references/structure-match.md`
