# Learned Rules

Rules distilled from repeated corrections. These have the **same weight as non-negotiable rules** in SKILL.md — violating a learned rule is treated as a bug.

Rules are promoted here from `corrections-log.md` when they meet promotion criteria (count >= 2, high severity, or explicit user instruction).

---

### LR-026 — Prefer dedicated backend queries for counts and aggregations
- **Promoted from**: User explicit instruction (2026-04-14)
- **Category**: other
- **Modes**: implement, fix, build
- **Rule**: When the frontend needs a count, total, or any aggregation (e.g., total row count for a badge), prefer a dedicated backend query or an existing field from a server response (like `totalRows` from SSRM) over workarounds like fetching rows with `startRow: 1, endRow: 2` just to read `totalRows`. If a dedicated count query doesn't exist, flag it as a backend gap rather than hacking an existing data query to extract metadata. The backend can compute counts and aggregations via SQL far more efficiently than the frontend can infer them from paginated data responses.
- **Why**: Fetching actual row data (even 1-2 rows) to get a count wastes compute and database load. The backend can run a `COUNT(*)` query orders of magnitude cheaper. Using data queries for metadata also couples the UI to implementation details of the datasource response shape. Dedicated count/aggregation endpoints are the scalable pattern.

### LR-025 — Use Field.LazyAutocomplete for all reference data FK dropdowns
- **Promoted from**: User explicit instruction (2026-04-14)
- **Category**: other
- **Modes**: implement, fix, build
- **Rule**: When a form field is a foreign key that maps to a `useReferenceData` key, use `Field.LazyAutocomplete` with the `referenceKey` prop instead of manually calling `useReferenceData` + `Field.Autocomplete`. This eliminates boilerplate (query hooks, option types, option prop drilling) and lazy-loads data only when the dropdown is opened. For non-standard shapes (e.g., `packagedProducts` with extra fields), use the `mapOption` prop to normalize to `{ id, name }`.
- **Why**: Manual `useReferenceData` + `Field.Autocomplete` requires ~20 lines of boilerplate per dropdown (query call, option extraction, type, prop drilling). `Field.LazyAutocomplete` reduces it to one line with `referenceKey`. It also defers the network request until the user actually opens the dropdown — saving bandwidth when users don't interact with every FK field.

### LR-024 — All UI must be responsive; use MUI breakpoints for grids, spacing, and layout
- **Promoted from**: User explicit instruction (2026-04-14)
- **Category**: skipped-state
- **Modes**: implement, fix, build, redesign
- **Rule**: Every component must work at mobile, tablet, and desktop widths. Use MUI responsive `gridTemplateColumns` (e.g., `{ xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }`), responsive `gap`/`p`/`fontSize` via breakpoint objects, and `flexWrap: 'wrap'` where needed. Fixed-width grids like `repeat(4, 1fr)` without breakpoints are a bug — they overflow on small screens. Check stat card grids, header layouts, button rows, and toolbar content at narrow widths before declaring done.
- **Why**: The stat card grid used a fixed `repeat(4, 1fr)` which crushed cards at mobile width — labels and icons overlapped. Responsiveness is not optional; it's part of the exit checklist for every code-producing mode.

### LR-023 — Extract repeated UI into shared components in packages/ui
- **Promoted from**: User explicit instruction (2026-04-14)
- **Category**: skipped-component
- **Modes**: implement, fix, build, redesign
- **Rule**: When the same UI pattern appears in more than one place (e.g., stat cards, page headers, expandable panels), extract it into a shared component under `packages/ui/src/components/` and reuse it from both locations. Don't duplicate the same JSX across files — if two pages render the same card/header/layout, that's a shared component waiting to be created. Props for the varying parts, shared structure in one file.
- **Why**: Duplicated UI drifts over time — one copy gets fixed, the other doesn't. Shared components in `packages/ui` are the project's canonical location for reusable UI. Keeping them there makes discoverability easy and ensures consistency across pages.

### LR-022 — Always use AG Grid for tables; match mockup visuals via cellRenderers
- **Promoted from**: IMPL-005 (2026-04-14), high severity
- **Category**: assumption-error
- **Modes**: implement, build, redesign
- **Rule**: AG Grid is the mandatory table component in this project. Never replace it with a custom MUI table, HTML table, or Box-based layout — even if the mockup looks simpler than what AG Grid renders by default. Use custom `cellRenderer` functions to match the mockup's visual style within AG Grid. The mockup defines the look; AG Grid + cellRenderers is the implementation tool.
- **Why**: Replacing AG Grid with a custom table breaks the project's standard data grid patterns (SSRM, sorting, filtering, column resizing, views). A custom table can't plug into `ServerSideDatasource`, `ViewsManager`, or any grid-level feature. The visual gap between a mockup and AG Grid is always solvable with cellRenderers.

### LR-021 — Extract the largest reusable boundary, not just the smallest visible duplication
- **Promoted from**: IMPL-004 (2026-04-14), count >= 2
- **Category**: assumption-error
- **Modes**: implement, build, redesign
- **Rule**: When told "same as X" or when two components share an identical structural pattern (modal, card, form, layout), identify the **largest reusable boundary** — not just the first obvious block. Ask: "what is the full repeated structure, and what are the only things that vary?" Extract the full pattern as a component with props for the varying parts. Don't extract a banner when the entire modal is the reusable unit.
- **Why**: Two rounds of corrections were needed because the smallest visible duplication (a banner) was extracted instead of the full shared pattern (an entire assign modal). When the scope of duplication is misjudged, the user has to correct twice — once for the initial miss, once for the correct boundary.

### LR-020 — Write comments like a developer, not like AI
- **Promoted from**: User explicit instruction (2026-04-14); reinforced 2026-04-17
- **Category**: style-drift
- **Modes**: all
- **Rule**: All comment forms — `//` lines, `/* */` blocks, AND JSDoc `/** */` — must read like notes a working developer writes for themselves: terse, practical, `why` over `what`, no restating the signature. Good: `// skip if no roles assigned`, `// stable ref — don't recreate on every render`, `// grid needs this for SSRM refresh`. Bad (reads as AI): multi-line JSDoc on internal route handlers, "When set, ... Defaults to X" prose on option fields (TS already shows the default), "POST /api/foo — Issues a ..." restatement of what the handler signature says. Specific rules:
  1. **No JSDoc on internal/private symbols** (route handlers, option interfaces consumed within the same package, local helpers). One `//` line, or nothing at all.
  2. **JSDoc only for genuinely public library exports** and even then: one short line, not a multi-paragraph description.
  3. **Never restate the signature**. `// POST /api/auth/chat-token — Issues a short-lived token` is redundant with the `export async function POST()` right below.
  4. **No "defaults to X" on `Type = 'default-value'` fields** — the default value itself documents it.
  5. **No "when set, ... falls back to ...". Compress to one clause**: `// direct-to-ELB path (ADR-013)`.
- **Why**: AI-style verbose JSDoc and multi-line prose comments stand out in code review and erode trust. Rule was originally promoted for `//` comments but later violated in JSDoc form because the exemption wasn't explicit. Now it's explicit: all comment forms, no exceptions.

### LR-017 — Backwards compatibility not required unless explicitly requested
- **Promoted from**: User explicit instruction (2026-04-13)
- **Category**: other
- **Modes**: all
- **Rule**: When making changes, backwards compatibility with prior implementations is NOT required by default. Replace, restructure, or remove old patterns entirely when it results in better code. Only maintain backwards compatibility if the user explicitly requests it for a specific change.
- **Why**: Clean, forward-looking implementations are preferred over compatibility shims. Backwards-compat constraints should be opt-in, not assumed.

### LR-016 — Prioritize scalable foundations over convenience
- **Promoted from**: User explicit instruction (2026-04-13)
- **Category**: other
- **Modes**: all
- **Rule**: When making implementation decisions, prioritize what constitutes the best foundation and scalability per frontend best practices, even if that means deviating from what's most convenient or closest to the current codebase. Quality of architecture takes precedence over path of least resistance.
- **Why**: Short-term convenience often creates long-term technical debt. The user values scalable, best-practice foundations over quick fixes or minimal-diff changes.

### LR-015 — Decompose code following existing project structure; ask before deviating
- **Promoted from**: User explicit instruction (2026-04-13)
- **Category**: other
- **Modes**: all
- **Rule**: When decomposing or restructuring code, follow the existing project's code structure and decomposition patterns. If frontend best practices dictate a different approach, ask the user before implementing the deviation — do not silently restructure.
- **Why**: Consistency with the existing codebase is important for team maintainability. Deviations from project conventions should be conscious decisions approved by the user, not unilateral assumptions.

### LR-014 — Avoid overfetching in mutation responses: return only `id`
- **Promoted from**: User explicit instruction (2026-04-10)
- **Category**: other
- **Modes**: implement, fix, build
- **Rule**: When writing GraphQL mutations (create, update), the response selection set should request only `{ id }` — not the full fragment. The grid refreshes via `refreshServerSide({ purge: true })` which re-fetches all data through the SSRM datasource anyway, so fetching the full entity in the mutation response is wasted bandwidth. Use fragments only in queries (list rows, detail views). Mutations should return `{ id }` only. Delete mutations already return a boolean/void — no change needed there.
- **Why**: Using full fragments (e.g., `...DemandPolicyFields`) in mutation responses fetches all fields twice — once in the mutation response (which is discarded) and again when the grid refreshes. This is overfetching. The mutation response is only used to confirm success; the actual data refresh comes from `refreshServerSide`.

### LR-013 — Nav route checklist: update all dependent files when adding a new page/route
- **Promoted from**: User explicit instruction (2026-04-10)
- **Category**: incomplete-phase
- **Modes**: build
- **Rule**: When adding or modifying a route in `nav-config-floating.tsx`, always update **all** of these files as a checklist:
  1. `packages/constants/src/paths.ts` — add the route path
  2. `apps/scm/src/app/dashboard/<route>/page.tsx` — create the Next.js page
  3. `apps/scm/src/sections/<route>/index.ts` — barrel export
  4. `apps/scm/src/sections/<route>/view/<name>-list-view.tsx` — list view component
  5. `packages/constants/src/mapping/path-permission-map.ts` — add route permissions with **actual entity permissions** (e.g., `readOnly('EntityName')` / `curd('EntityName')`), NOT empty arrays. Empty arrays prevent "Associated Pages" from appearing in role permissions because `buildEntityRouteMap` discovers entities by scanning permission requirements.
  6. `packages/utils/src/permission-checks/get-permissions-for-path.ts` — add route matcher to the `ROUTES` array (regex → permissionsByPath resolver). Without this, `getPermissionsForPath` returns `null` and the PermissionGuard blocks the route.
  7. `packages/types/src/permission-entity/index.ts` AND `apps/scm/src/types/permission-entity.ts` — add the entity name to the `PermissionEntity` union type in BOTH files if it doesn't exist yet. Without this, TypeScript rejects the entity name in `readOnly()`/`curd()`.
  8. `apps/scm/src/utils/entity-route-mapping.ts` — add `NAV_ENTITY_ROUTES` entry mapping the entity name to its route path (for "Associated Pages" in role permissions)
  9. `apps/scm/src/layouts/nav-config-floating.tsx` — add the nav item
  Do not consider the task done until all 9 files are addressed. Missing any one causes navigation failures, permission blocks, type errors, or missing "Associated Pages" in roles.
- **Why**: Multiple rounds of fixes were needed because files were missed: (1) empty permission arrays caused "Associated Pages" to not appear — `buildEntityRouteMap` needs actual entity references in `minimum`/`full` to discover entity→route associations. (2) Missing `get-permissions-for-path.ts` route matcher caused navigation to fail silently. (3) Missing entity in `PermissionEntity` type caused TS errors. (4) Missing `entity-route-mapping.ts` entry caused fallback to fail. All 9 files are in different packages — easy to miss one.

### LR-011 — Fix unused variables in all touched and affected files before declaring done
- **Promoted from**: User explicit instruction (2026-04-10), merged with LR-008
- **Category**: incomplete-phase
- **Modes**: implement, fix, redesign, build
- **Rule**: When editing a file, check for unused imports, variables, and dead code in that file and remove them. Also check files **outside your direct edits** that may break due to cascading changes (e.g., a shared component whose consumer changed). Fixes: remove unused imports, prefix unused but required props/params with `_` (e.g., `currentUser: _currentUser`), delete unused local variables. Do not scan or modify files you haven't touched unless your edits caused a cascading break. Run the quality gate (LR-009) on all potentially affected packages.
- **Why**: TS strict mode treats unused declarations as build errors (`TS6133`). A single leftover unused variable in any package breaks the entire build. Scoping cleanup to touched + affected files avoids both leftover warnings and unrelated churn.

### LR-010 — Create separate skeleton components for loading states
- **Promoted from**: User explicit instruction (2026-04-09)
- **Category**: incomplete-phase
- **Modes**: implement, build, redesign
- **Rule**: When building or modifying a component that has a loading state (data fetching, permissions gating, hydration), create a dedicated skeleton component in a separate file within the same folder (e.g., `nav-skeleton.tsx` alongside `nav-floating.tsx`, or `sales-order-detail-skeleton.tsx` alongside `sales-order-detail-view.tsx`). The skeleton must mirror the real component's layout structure (same dimensions, spacing, border-radius, zones) using MUI `Skeleton` components. Only create skeletons where a loading state actually exists — do not add them preemptively to components that render synchronously.
- **Why**: Generic spinners or mismatched skeletons cause layout shift and look unpolished. Keeping the skeleton in a separate file in the same folder makes it easy to find and update when the real component's layout changes. Inline skeleton logic clutters the main component.

### LR-009 — Mandatory quality gate: eslint fix + type-check on EVERY edit, no exceptions
- **Promoted from**: User explicit instruction (2026-04-07), merged with LR-001, LR-003, LR-004. Updated 2026-04-15.
- **Category**: incomplete-phase
- **Modes**: implement, fix, redesign, build
- **Rule**: After EVERY file edit — no matter how trivial (even a one-line text change) — run both checks automatically before responding:
  1. `pnpm eslint --fix <touched-files>` — fix formatting, import order, and indentation on only the files you touched.
  2. `mcp__ide__getDiagnostics` with the file URI — instant, scoped type-check via the IDE's TypeScript language server. Call once per touched file. If the IDE tool is unavailable, note it explicitly rather than silently skipping.
  Do NOT run project-wide `tsc --noEmit` — it type-checks the entire project (thousands of files), takes 30-60+ seconds, and is wasteful. If either check finds issues, fix them before responding. Common pitfalls: unused imports, implicit `any` params, AG Grid `cellStyle` needing `as CellStyle` assertion, missing type imports, import sort order, broken import paths after moving/renaming.
  **No excuses for skipping**: "trivial edit", "just a text change", "only removed a line" are NOT valid reasons to skip. The quality gate runs on every edit, period.
- **Why**: Repeatedly forgetting to run eslint + type-check leads to broken imports, unused variables, and formatting issues that surface later during build or push. Running these checks is cheap (seconds) and catches problems immediately. Skipping them creates compounding debt.

### LR-007 — SSRM tables must use invalidate with router.refresh(), not refetchQueries
- **Promoted from**: User explicit instruction (2026-04-07)
- **Category**: logic-destroyed
- **Modes**: implement, fix, build
- **Rule**: When a page uses `useCustomMutation` and the table is server-side (SSRM via `ServerSideDatasource`), never use `refetchQueries`. Instead, use the `invalidate` option with a callback that calls both `gridApiRef.current?.refreshServerSide({ purge: true })` and `router.refresh()`. Pass `gridApiRef` to `BusinessObjectListViewPage` via `otherProps={{ gridApiRef }}`.
- **Why**: `refetchQueries` targets Apollo cache queries by document node, but SSRM tables fetch data through `ServerSideDatasource` which bypasses the normal Apollo query cache. Without `router.refresh()` + grid API refresh, the table shows stale data after create/update/delete mutations.

### LR-005 — Read theme files first; use .main not .light; alpha >= 0.16 on dark surfaces
- **Promoted from**: User explicit instruction (2026-03-27)
- **Category**: theme-violation
- **Modes**: implement, fix, redesign, build, mockup
- **Rule**: Before writing any UI code, read `packages/ui/src/theme/theme-config.ts` and `theme-overrides.ts` to confirm available palette tokens. Use `theme.palette.<color>.main` as the default for visible text/borders — not `.light` or `.lighter` which may not exist or may be too faint. For tinted backgrounds on dark surfaces, use `alpha(theme.palette.<color>.main, 0.16)` as the minimum opacity — never below 0.16.
- **Why**: Low-contrast bugs kept appearing when using assumed color tokens (e.g., `info.light` invisible on dark surfaces). The project palette differs from MUI defaults, so tokens must be verified against the actual theme files, not assumed.

### LR-IC — Icon policy: react-icons only, varied families, no Iconify, no emoji
- **Promoted from**: Consolidated from LR-006, LR-012, LR-018, LR-019 (2026-04-14)
- **Category**: style-drift
- **Modes**: all
- **Rule**: All icons must be `react-icons` components. Specifically:
  1. **No Iconify strings** — never use string identifiers like `"mingcute:document-fill"`. For components accepting both `iconName` (string) and `icon` (ReactNode), always use the `icon` prop.
  2. **No emoji** — never use HTML emoji characters (`&#x1F6E1;`, etc.) as icon substitutes in mockups or code. In HTML mockups, use inline `<svg>` elements.
  3. **Varied families** — pick the best-fitting icon from any family: `hi2` (Heroicons), `lu` (Lucide), `ri` (Remix), `md` (Material Design), `tb` (Tabler), `pi` (Phosphor), etc. Don't default to one family.
  4. **Migrate shared components** — when a shared component only accepts `icon` as `string`, update its type to `string | React.ReactNode`. Flag as TODO if can't update immediately.
- **Why**: Iconify strings were used repeatedly despite earlier rules. Emoji render inconsistently and can't be themed. Defaulting to one icon family looks monotonous. This consolidated rule makes the policy unambiguous: zero Iconify, zero emoji, varied react-icons.

### LR-002 — Pixel-match every mockup detail during implement mode
- **Promoted from**: IMPL-002 (2026-04-02), user explicit instruction
- **Category**: style-drift
- **Modes**: implement
- **Rule**: In implement mode, treat the mockup as an exact spec, not a rough guide. Before submitting, visually diff every element: text casing/transforms, icon choices, chip/badge styles, layout direction (row vs wrap vs stack), spacing, button variants (outlined vs contained vs text), color tokens, column layout, and badge placement. If data casing doesn't match the mockup (e.g., backend returns "ADMIN" but mockup shows "Admin"), add a formatter. If mockup shows inline chips, remove flexWrap. Match it exactly.
- **Why**: Multiple correction rounds were needed because the initial implementation deviated in many small ways — uppercase role names, stacked chips, wrong icon, missing star icon in badge, wrong button variants, extra table column. Each one required a separate fix request.
