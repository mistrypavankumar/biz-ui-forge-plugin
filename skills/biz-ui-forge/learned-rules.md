# Learned Rules

Rules distilled from repeated corrections. These have the **same weight as non-negotiable rules** in SKILL.md — violating a learned rule is treated as a bug.

Rules are promoted here from `corrections-log.md` when they meet promotion criteria (count >= 2, high severity, or explicit user instruction).

---

### LR-011 — Fix unused variables in all touched and affected files before declaring done
- **Promoted from**: User explicit instruction (2026-04-10)
- **Category**: incomplete-phase
- **Rule**: When editing a file causes a variable, import, or destructured prop to become unused (e.g., removing the only usage of an import, or removing a component that consumed a prop), fix the unused reference immediately — do not leave it for the user to discover via a failing build. Fixes: remove unused imports, prefix unused but required props/params with `_` (e.g., `currentUser: _currentUser`), delete unused local variables. Also check files **outside your direct edits** that may break due to cascading changes (e.g., a shared component whose consumer changed). Run the type-check gate (LR-009) on all potentially affected packages, not just the files you directly edited.
- **Why**: TS strict mode treats unused declarations as build errors (`TS6133`). A single leftover unused variable in any package breaks the entire build. This happened when removing a component consumer left an unused prop in a shared package file, which was only caught when the user tried to build.

### LR-010 — Create separate skeleton components for loading states
- **Promoted from**: User explicit instruction (2026-04-09)
- **Category**: incomplete-phase
- **Rule**: When building or modifying a component that has a loading state (data fetching, permissions gating, hydration), create a dedicated skeleton component in a separate file within the same folder (e.g., `nav-skeleton.tsx` alongside `nav-floating.tsx`, or `sales-order-detail-skeleton.tsx` alongside `sales-order-detail-view.tsx`). The skeleton must mirror the real component's layout structure (same dimensions, spacing, border-radius, zones) using MUI `Skeleton` components. Only create skeletons where a loading state actually exists — do not add them preemptively to components that render synchronously.
- **Why**: Generic spinners or mismatched skeletons cause layout shift and look unpolished. Keeping the skeleton in a separate file in the same folder makes it easy to find and update when the real component's layout changes. Inline skeleton logic clutters the main component.

### LR-009 — Mandatory quality gate: eslint fix + type-check before done
- **Promoted from**: User explicit instruction (2026-04-07)
- **Category**: incomplete-phase
- **Rule**: Before declaring any fix/implement task complete, run both quality checks on all touched files: 1) `pnpm eslint --fix <touched-files>` to fix formatting, import order, and indentation. 2) `cd apps/scm && npx tsc --noEmit --project tsconfig.json 2>&1 | grep "<touched-file>"` to verify zero type errors. If either check fails, fix the issues before responding. Never present work as done with outstanding lint warnings or TS errors in modified files.
- **Why**: Multiple rounds of corrections were needed because lint/formatting and type errors were left in touched files. The user expects clean code on every response — not a follow-up "should I fix the lint?" question. This is a hard gate, not optional.

### LR-008 — Remove unused code only in touched files
- **Promoted from**: User explicit instruction (2026-04-07)
- **Category**: incomplete-phase
- **Rule**: When editing a file, check for unused imports, variables, and dead code **only in that file**. If found, remove them as part of the edit. Do not scan or modify files you haven't touched. Unused code cleanup is scoped to touched files only.
- **Why**: Leaving unused imports/variables in touched files causes lint warnings the user has to clean up later. But modifying untouched files introduces unrelated changes and risks breaking things outside the task scope.

### LR-007 — SSRM tables must use invalidate with router.refresh(), not refetchQueries
- **Promoted from**: User explicit instruction (2026-04-07)
- **Category**: logic-destroyed
- **Rule**: When a page uses `useCustomMutation` and the table is server-side (SSRM via `ServerSideDatasource`), never use `refetchQueries`. Instead, use the `invalidate` option with a callback that calls both `gridApiRef.current?.refreshServerSide({ purge: true })` and `router.refresh()`. Pass `gridApiRef` to `BusinessObjectListViewPage` via `otherProps={{ gridApiRef }}`.
- **Why**: `refetchQueries` targets Apollo cache queries by document node, but SSRM tables fetch data through `ServerSideDatasource` which bypasses the normal Apollo query cache. Without `router.refresh()` + grid API refresh, the table shows stale data after create/update/delete mutations.

### LR-006 — Use varied react-icons families, not just Phosphor
- **Promoted from**: User explicit instruction (2026-04-02)
- **Category**: style-drift
- **Rule**: When adding react-icons, pick the best-fitting icon from any family — `hi2` (Heroicons), `lu` (Lucide), `ri` (Remix), `md` (Material Design), `tb` (Tabler), `pi` (Phosphor), etc. Do not default to `react-icons/pi` for everything.
- **Why**: User prefers variety and best-fit icons rather than always falling back to Phosphor Icons. Different icon families have different strengths (e.g., `lu` for clean outlines, `hi2` for solid fills).

### LR-005 — Read theme files first; use .main not .light; alpha >= 0.16 on dark surfaces
- **Promoted from**: User explicit instruction (2026-03-27)
- **Category**: theme-violation
- **Rule**: Before writing any UI code, read `packages/ui/src/theme/theme-config.ts` and `theme-overrides.ts` to confirm available palette tokens. Use `theme.palette.<color>.main` as the default for visible text/borders — not `.light` or `.lighter` which may not exist or may be too faint. For tinted backgrounds on dark surfaces, use `alpha(theme.palette.<color>.main, 0.16)` as the minimum opacity — never below 0.16.
- **Why**: Low-contrast bugs kept appearing when using assumed color tokens (e.g., `info.light` invisible on dark surfaces). The project palette differs from MUI defaults, so tokens must be verified against the actual theme files, not assumed.

### LR-004 — Run eslint --fix on touched files without asking permission
- **Promoted from**: User explicit instruction (2026-04-02)
- **Category**: style-drift
- **Rule**: After writing or editing any file during UI implementation or bug fix, immediately run `pnpm eslint --fix <touched-files>` without asking the user for permission. This is a mandatory post-edit step, not an optional action that needs approval.
- **Why**: User repeatedly had to remind to format files. The formatting step should be automatic and silent — never prompt "shall I run eslint?" or wait for confirmation.

### LR-003 — Run type-check only on changed files, fix errors, no permission needed
- **Promoted from**: TS-001 (2026-04-02), user explicit instruction
- **Category**: incomplete-phase
- **Rule**: After creating or modifying any UI component, run `cd apps/scm && npx tsc --noEmit --project tsconfig.json 2>&1 | grep "<changed-file>"` to type-check scoped to the project but filtered to only show errors in files you touched. Fix all TypeScript errors before presenting work as complete. Do this automatically without asking the user for permission — same as eslint --fix. Common pitfalls: unused imports, AG Grid `cellStyle` needing `as CellStyle` assertion in array literals, missing type imports.
- **Why**: Full project type-check is slow and may surface unrelated errors. Bare `tsc --noEmit <file>` fails on TSX without project config. User wants scoped checks on changed files only, run silently without approval. UI work is not done until it compiles clean.

### LR-002 — Pixel-match every mockup detail during implement mode
- **Promoted from**: IMPL-002 (2026-04-02), user explicit instruction
- **Category**: style-drift
- **Rule**: In implement mode, treat the mockup as an exact spec, not a rough guide. Before submitting, visually diff every element: text casing/transforms, icon choices, chip/badge styles, layout direction (row vs wrap vs stack), spacing, button variants (outlined vs contained vs text), color tokens, column layout, and badge placement. If data casing doesn't match the mockup (e.g., backend returns "ADMIN" but mockup shows "Admin"), add a formatter. If mockup shows inline chips, remove flexWrap. Match it exactly.
- **Why**: Multiple correction rounds were needed because the initial implementation deviated in many small ways — uppercase role names, stacked chips, wrong icon, missing star icon in badge, wrong button variants, extra table column. Each one required a separate fix request.

### LR-001 — Auto-format touched files after writing code
- **Promoted from**: User instruction (2026-04-02)
- **Category**: style-drift
- **Rule**: After writing or editing any file, run `pnpm eslint --fix <file>` on **only** the files you touched. Do not run project-wide lint/format commands.
- **Why**: Import ordering, spacing, and formatting rules are enforced by ESLint. Manual formatting attempts often get it wrong (e.g., import sort order, spacing between import groups). Running `eslint --fix` on touched files catches these automatically and avoids churn from unrelated files.
