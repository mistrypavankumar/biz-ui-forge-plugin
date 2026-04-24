# Learned Rules

Rules distilled from repeated corrections. These have the **same weight as non-negotiable rules** in SKILL.md — violating a learned rule is treated as a bug.

Rules are promoted here from `corrections-log.md` when they meet promotion criteria (count >= 2, high severity, or explicit user instruction).

---

### LR-034 — All mockups live under `docs/ui-mockups/` and the folder is gitignored
- **Promoted from**: User explicit instruction (2026-04-23)
- **Category**: other
- **Modes**: mockup, variant
- **Rule**: Every HTML mockup produced in `mockup` or `variant` mode must be saved under `docs/ui-mockups/<ui-name>/` — not `docs/mockups/`, not `docs/design/mockups/`, not anywhere else. The folder is treated as **local-only visual exploration** and **must be listed in the repo's `.gitignore`** so the HTML files never reach the remote. Concrete requirements:
  1. File path: `docs/ui-mockups/<kebab-case-feature-name>/v1.html`, `v2.html`, etc. — variants still increment per LR-009 / skill's Variant section.
  2. On the **first** mockup written to this folder during a session, check `.gitignore` for an entry matching `docs/ui-mockups/` or `docs/ui-mockups/**`. If missing, add it (single-line edit, no explanation comment — the path is self-documenting). If present, proceed without touching gitignore.
  3. If existing mockups sit in `docs/mockups/` (the old SKILL.md default), **do not silently migrate them** — flag to the user and ask whether to move them. Adding new mockups under `docs/ui-mockups/` alongside old ones is acceptable short-term; the user decides when to consolidate.
  4. The SKILL.md's own "Save mockups under `docs/mockups/<ui-name>/`" line is superseded by this rule. Treat LR-034 as the source of truth.
  5. Applies to both **mockup** mode (fresh concept) and **variant** mode (increments of an existing file). Does not apply to production code (e.g., real `.tsx` components are never stored here).
  6. Do not create `docs/ui-mockups/README.md` or any other non-mockup file in this folder unless the user asks — the folder is for HTML visual exploration only, and README churn would need its own gitignore exception.
- **Why**: Mockups are a designer-side exploration artifact, not production code. Committing them to the remote bloats the repo, clouds PR diffs with generated HTML, and exposes early-stage design ideas to downstream consumers who may mistake them for the current production UI. Keeping them local (`docs/ui-mockups/` + gitignore) gives the design surface a persistent local home without polluting git history. The rule also stabilizes the path — switching between `docs/mockups/` (old default) and other ad-hoc locations causes the user to waste time hunting for recent work. One canonical folder, always gitignored.

### LR-033 — When implementing a mockup into real code, mirror the mockup byte-for-byte — never re-interpret values
- **Promoted from**: User explicit instruction (2026-04-23) after four correction rounds on the ChatWidget S8 celebration (FIX-040, FIX-041, and two follow-up position fixes)
- **Category**: style-drift
- **Modes**: implement, fix, redesign, build
- **Rule**: When the user asks to translate a specific mockup (HTML file, Figma node, screenshot with a source mockup behind it) into production code, the mockup **is the spec**. Copy every numeric and structural value 1:1 from the mockup CSS into the production sx — do not substitute your own "better" numbers, shard counts, easing curves, palette blends, keyframe shapes, or timing.
  1. **Read the mockup's exact CSS before writing code.** Grep the mockup file for the feature (e.g. `.confetti`, `.s-celebrate .daxbot-btn`, `@keyframes celebrate-bg`), copy out every property+value. That is your value table.
  2. **Mirror: shard count, colors (exact hex), offsets (`--cx`, `--cy`), rotations, delays, durations, easing (`ease-out` vs `ease-in-out`), border-radius, z-index, start/end positions (`top: -4px` vs `top: 50%`), keyframe %-frames, opacity transitions.** A mockup with 4 shards gets 4 shards in code, not 6. `2s ease-out` stays `2s ease-out`, not `1.8s ease-in`. `top: -4px` stays `top: -4px`, not `top: 0` or `top: 50%`.
  3. **Do NOT add values the mockup doesn't have** — no scale-pop if the mockup has no scale, no `--cy` variable if the mockup's Y is hardcoded, no extra keyframe stops. If the mockup only has 0% / 10% / 100%, don't insert a 15% frame.
  4. **Do NOT drop values the mockup has** — every CSS property in the mockup's target selector belongs in the sx unless it's a layout concern owned by the surrounding MUI component. Missing `border-radius: 1px` or `pointer-events: none` will break the look subtly.
  5. **The only acceptable re-interpretation is mapping CSS vars to theme tokens** (e.g. `var(--primary-main)` → `theme.palette.primary.main`, `var(--grey-500-alpha-08)` → `alpha(theme.palette.grey[500], 0.08)`). Everything else — pixel offsets, durations, percentages, gradient stops — stays literal.
  6. **When in doubt, re-open the mockup file and diff your sx against the mockup's CSS rule-by-rule.** If your code deviates from the mockup, either the user intended the deviation (rare and usually explicit) or it's a bug.
  7. **If the mockup uses CSS custom properties + single keyframe for per-element variance** (as v3.html/v4.html do with `--cx`/`--cr`), your sx must mirror that pattern — single `@keyframes` body, per-element CSS custom properties on the rendered element. Do not inline keyframe bodies that bake in per-element values (LR-033 reinforces FIX-041).
- **Why**: The S8 celebration implementation went through four correction cycles because I kept "improving" the mockup's values instead of copying them: chose 6 shards instead of 4, swapped `ease-out` for `ease-in`, moved the start position, added a scale animation, invented new dx/dy tuples, and changed keyframe percentages. Each "improvement" drifted the production further from the approved mockup, and each correction was the user telling me to go back to what the mockup already specified. The mockup IS the design decision — treating it as inspiration rather than spec wastes the user's time and my turns. Copying values literally is slower to feel creative about but faster to ship correctly.

### LR-032 — Always import from the deepest sub-path; never from a barrel index
- **Promoted from**: User explicit instruction (2026-04-23) after bundle-size inspector showed `@daxwell/ui/hooks` barrel import pulling hundreds of kB into `supplier-fulfillment-list-view.tsx`
- **Category**: framework-leak
- **Modes**: all
- **Rule**: When importing from a package that exposes both a barrel (`./hooks`, `./components`, `./utils`, `./index`) and specific sub-paths, **always use the specific sub-path**. The barrel form is banned unless the symbol genuinely has no sub-path export.
  1. `@daxwell/ui/hooks` → `@daxwell/ui/hooks/<specific-hook>` (e.g., `@daxwell/ui/hooks/use-location-filter`, not `@daxwell/ui/hooks`).
  2. `@daxwell/ui/components` → `@daxwell/ui/components/<specific-component>` (e.g., `@daxwell/ui/components/transaction-quick-view`).
  3. `@daxwell/utils` / `@daxwell/constants` / `@daxwell/graphql` / `@daxwell/types` → use the narrowest sub-path the package exposes in its `exports` map. Barrel `@daxwell/utils` is banned when `@daxwell/utils/<topic>` resolves.
  4. `@mui/material` destructured (`import { Box, Typography } from '@mui/material'`) → split into per-component deep imports: `import Box from '@mui/material/Box';` `import Typography from '@mui/material/Typography';`. Same for `@mui/material/styles` (use the destructured named form — that one IS the sub-path).
  5. `@mui/icons-material` destructured → per-icon deep import: `import ListIcon from '@mui/icons-material/List';` — never `import { List } from '@mui/icons-material'`.
  6. `react-icons` — never import from `react-icons` bare. Always use the family sub-path: `react-icons/hi2`, `react-icons/lu`, `react-icons/ri`, etc.
  7. **Verifying**: the VS Code "Import Cost" extension (or the `why` output on a built chunk) should show every line under a few kB; any `@daxwell/*` barrel import that surfaces >10 kB gzipped is a violation to fix on the spot.
  8. When adding a new shared primitive to a package, **also add an `exports` entry for its specific sub-path** (e.g., `./hooks/use-new-hook`) so consumers can deep-import it. If the `exports` map doesn't expose the sub-path, fix the package's `package.json` first, then import.
  9. The rule applies to every code-producing mode (implement, fix, redesign, build, mockup-to-code). No exceptions for "it's just one symbol" — one symbol from a barrel can drag the whole barrel into the bundle when sideEffects isn't perfectly configured.
- **Why**: The supplier-fulfillment view had `import { useLocationFilter } from '@daxwell/ui/hooks'`. Because `@daxwell/ui/hooks/index.ts` re-exports every hook and those hooks transitively import heavy deps (apollo client, MUI components, icon packs), Next's Turbopack couldn't tree-shake down to just `useLocationFilter` — the whole barrel landed in the page chunk. Deep-importing from `@daxwell/ui/hooks/use-location-filter` brings in only that hook's own graph. Same principle applies to `@mui/material` destructured imports (each top-level named export pulls the full module graph pre-tree-shake) and to `react-icons` which explicitly requires family sub-paths. This is the single biggest bundle-size lever in this repo.

### LR-031 — Never declare a fix/edit done until eslint + type-check results are actually seen and green
- **Promoted from**: User explicit instruction (2026-04-22) after repeat violation during `--fix` of build error
- **Category**: incomplete-phase
- **Modes**: implement, fix, redesign, build
- **Rule**: LR-009 requires `pnpm eslint --fix <touched-files>` and `mcp__ide__getDiagnostics` on every edit. This rule closes the most common shortcut: **treating a check as "done" when it has been started, not when it has returned**. Specific requirements:
  1. **Do not respond to the user with a completion claim while a check is still running in the background.** If `pnpm --filter scm type-check` or any lint command is running (`run_in_background: true`, a detached Monitor task, or a shell job), the fix is **not done**. Wait for the actual exit code and output, then respond.
  2. **Run eslint --fix explicitly on the touched file as its own Bash call**, even when you believe the edit was purely a rename/one-liner. Never skip it because "it was just an import swap" — that was the exact excuse pattern that produced this rule.
  3. **Call `mcp__ide__getDiagnostics` with the file URI** after the edit, and confirm zero errors scoped to your touched file before responding. Pre-existing diagnostics on other lines don't block, but if new-diagnostics notifications arrive, triage them: own the ones your edit introduced, explicitly note pre-existing ones as out-of-scope.
  4. **Kicking off a type-check and then saying "Let me confirm the build now succeeds" is a violation** — confirmation must land in the response, not be deferred to a future turn.
  5. If the full type-check is genuinely too slow to block on (multi-minute project-wide), fall back to `mcp__ide__getDiagnostics` on the touched file(s) — that is the scoped, fast path and it counts. But do not ship the response without *one* of {scoped diagnostics green, completed type-check output} visible to the user.
- **Why**: On the 2026-04-22 `--fix` run, the build error was fixed with a 2-line rename, type-check was launched in a background shell, eslint was never invoked explicitly, and the response to the user implied completion before either verification returned. The user caught it immediately. The failure mode is subtle because starting a check *feels* like doing the check — but until the exit code is known, nothing is proven. This rule makes the distinction explicit so the shortcut cannot recur.

### LR-030 — No comments on single-line / small changes; only on new reusable components or functions
- **Promoted from**: User explicit instruction (2026-04-21)
- **Category**: style-drift
- **Modes**: all
- **Rule**: Do not attach a comment (neither inline nor leading line) to a single-line change, a property tweak, a one-liner edit, or a small addition. The specific trigger: adding `errorPolicy: 'all'` to a query with a justifying comment above it — that comment must be dropped. Apply this broadly:
  1. **Never** add a comment explaining WHY a single-line prop/value was set (e.g., `// tolerate X`, `// for Y reason`, `// workaround for Z`). The PR description or commit message carries the rationale, not the code.
  2. **Never** add a leading comment on a small addition like a new import, a new optional chain, a new default fallback, or a toggle from one value to another.
  3. **Comments are allowed only** when the edit creates a new standalone reusable primitive — a new component in `packages/ui`, a new shared hook, a new utility function in `packages/utils` — and even then the comment must match LR-020 (terse, why-focused, no signature restatement).
  4. **Do not resurrect rationale comments after they're removed**. If a reviewer deletes a comment, treat it as deleted in this file forever — don't re-add it on the next edit pass.
- **Why**: Per-line rationale comments on small edits create noise, rot quickly (the justification becomes wrong after the next refactor), and duplicate information the PR/commit already carries. Comments like `// tolerate non-null bubble on nested AppUserDefaultRole.defaultRole` next to an `errorPolicy: 'all'` line are exactly the pattern the user rejects: the reader can see the property, and the backing story belongs outside the code. Reserve comments for genuinely new abstractions where future consumers benefit from a one-line intent statement.

### LR-029 — Check-mode findings are persisted under `docs/checks/` with a deletion-on-fix lifecycle
- **Promoted from**: User explicit instruction (2026-04-20)
- **Category**: incomplete-phase
- **Modes**: check, fix, implement
- **Rule**: Every `--check` run produces two deliverables:
  1. **Inline chat output** — the usual risk-rated finding list + summary/verdict + non-findings notes, so the user sees it immediately.
  2. **Persisted markdown file** — written to `docs/checks/<feature-slug>-logic-check.md` with the same content. File header includes `Date`, `Mode: --check`, `Status: <Deferred | In Progress | etc.>`, and the list of files reviewed. This happens automatically as part of check mode — never wait to be asked.
  **Lifecycle after the check:**
  - When a finding from that file is later implemented (via `--fix`, `--implement`, or ad-hoc edits), update the file: strike through / remove the addressed findings and decrement the summary counters.
  - When ALL findings in the file are addressed, **delete the file** from `docs/checks/`. The folder represents the **open backlog** of known issues, so an empty-folder state means nothing to fix.
  - When a partial set is fixed, keep the file around with only the remaining findings — do not leave stale "already fixed" entries in it.
  - Slug naming: kebab-case feature name + `-logic-check.md` (e.g. `auto-logout-logic-check.md`, `sales-order-detail-logic-check.md`).
- **Why**: Inline chat output vanishes between sessions and git history — findings get lost, so the "check was run" information never translates into follow-up fixes. Persisting under `docs/checks/` makes the backlog visible in the repo, reviewable in PRs, and trivially greppable. The deletion-on-fix convention keeps the folder as a live health indicator rather than a graveyard of stale reports.

### LR-028 — Promote reusable hooks/utilities to a global location; never import across sections
- **Promoted from**: User explicit instruction (2026-04-20)
- **Category**: style-drift
- **Modes**: all
- **Rule**: Any hook, utility, or component consumed by 2+ sections must live in a **global shared location**, not in a section folder:
  1. Shared UI components → `packages/ui/src/components/` (imported as `@daxwell/ui/components/*`)
  2. Shared hooks → `packages/ui/src/hooks/` (imported as `@daxwell/ui/hooks/*`)
  3. Shared utilities → `packages/utils/src/` (imported as `@daxwell/utils/*`)
  4. Shared types → `packages/types/src/` (imported as `@daxwell/types`)
  5. Shared constants → `packages/constants/src/` (imported as `@daxwell/constants`)
  Never do `import { xxx } from '@/sections/<some-other-section>/...'` — that creates cross-section coupling. When you encounter an existing section-local file that a second section needs (e.g., `useSectionMeta` from `@/sections/xwalk/shared`), **promote it first** by moving the file to the appropriate `packages/*` location, updating the original consumer's import, then importing from the new global path.
- **Why**: Section-to-section imports tangle feature modules together: refactoring one section breaks an unrelated section, ownership becomes ambiguous, and the file's discoverability is poor (nobody looks inside another section for shared code). Moving to `packages/*` makes the dependency explicit, gives the code a canonical home, and lets ESLint rules enforce it. LR-023 already covers this for UI components — LR-028 extends it to hooks/utilities/types and makes the "don't cross-import between sections" negative rule explicit.

### LR-027 — Adding a nav entry always scaffolds a matching page + section view stub
- **Promoted from**: User explicit instruction (2026-04-20)
- **Category**: incomplete-phase
- **Modes**: all
- **Rule**: Whenever a new item is added to `apps/scm/src/layouts/nav-config-floating.tsx` (or any nav config), also scaffold the minimum files needed for the route to resolve without 404:
  1. `apps/scm/src/app/dashboard/<parent>/<route-folder>/page.tsx` — Next.js route file. Use the accounting-item-categories template:
     ```tsx
     import type { Metadata } from 'next';
     import { PUBLIC_CONFIG } from '@daxwell/configs/public';
     import { <Name>ListView } from '@/sections/<parent>/pages/<route-folder>/view/<route-folder>-list-view';

     export const metadata: Metadata = {
       title: `<Title> | Dashboard - ${PUBLIC_CONFIG.appNames.scm}`,
     };

     export default function Page() {
       return <<Name>ListView />;
     }
     ```
  2. `apps/scm/src/sections/<parent>/pages/<route-folder>/view/<route-folder>-list-view.tsx` — a minimal `'use client'` stub that renders a single placeholder line of text (e.g., `<Typography>Transportation Handling Unit — coming soon</Typography>`). No data fetching, no grids, no modals — just enough for the page to render.
  3. The route folder kebab-case must match the URL segment from `paths.ts` exactly (if `paths.ts` has a typo, the folder keeps the typo; flag the typo separately but don't silently diverge).
  This runs alongside the LR-013 checklist — LR-013 covers the full production route (permissions, entity mapping, etc.) for finished features. LR-027 covers the **minimum scaffold on every nav-add** so the link is never broken even before the page is fully built.
- **Why**: Adding a nav item without a matching page file produces a 404 for anyone who clicks it. The user wants the stub page file and a stub section view created automatically so the link works end-to-end from the moment the nav item ships. Accounting-item-categories is the canonical template.

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
- **Promoted from**: User explicit instruction (2026-04-07), merged with LR-001, LR-003, LR-004. Updated 2026-04-15. Reinforced 2026-04-20 after repeat violation (FIX-027). **Reinforced again 2026-04-22 after repeat violation (FIX-035): ran eslint but skipped type-check across ~10 edits in one session.**
- **Category**: incomplete-phase
- **Modes**: implement, fix, redesign, build
- **Rule**: After EVERY file edit — no matter how trivial (even a one-character text change or label swap) — actively invoke **BOTH** checks before responding to the user. **Running only one of the two is treated identically to running neither** — the gate is AND, not OR.
  1. `pnpm eslint --fix <touched-files>` — fix formatting, import order, and indentation on only the files you touched. Must be called via Bash; do not assume prior edits covered it.
  2. `mcp__ide__getDiagnostics` with the file URI — instant, scoped type-check via the IDE's TypeScript language server. Call once per touched file. If the IDE tool is unavailable, note it explicitly rather than silently skipping.
  **Passive diagnostic notifications do not count as coverage.** If the ambient hook fires and reports "no issues" on its own, you still must actively invoke both tools. The reactive-diagnostics shortcut has already caused repeat skips (FIX-027, FIX-035) — treat every edit as if no auto-reporter exists.
  **The eslint-only shortcut is explicitly forbidden.** Running `pnpm eslint --fix` and then responding without invoking `mcp__ide__getDiagnostics` is the exact failure mode of FIX-035. Completeness of the gate is what's mandated, not the feel-good tick of having run _something_.
  Do NOT run project-wide `tsc --noEmit` — it type-checks the entire project (thousands of files), takes 30-60+ seconds, and is wasteful. If either check finds issues, fix them before responding. Common pitfalls: unused imports, implicit `any` params, AG Grid `cellStyle` needing `as CellStyle` assertion, missing type imports, import sort order, broken import paths after moving/renaming. **This check is the LAST action before every end-of-turn response in implement/fix/redesign/build modes — place it at the top of the pre-response self-check gate.**
  **No excuses for skipping**: "trivial edit", "just a text change", "only removed a line", "lint was clean so types are probably fine" are NOT valid reasons to skip. The quality gate runs on every edit, period.
  **Operational pattern**: after every Edit/Write, the very next tool call should be a Bash `pnpm eslint --fix <files>` AND an `mcp__ide__getDiagnostics` for each file. If multiple files were touched, both tools run once per file before any user-facing response.
- **Why**: Repeatedly forgetting to run eslint + type-check leads to broken imports, unused variables, and formatting issues that surface later during build or push. Running these checks is cheap (seconds) and catches problems immediately. Skipping them creates compounding debt. The eslint-only shortcut is the most common failure mode — eslint catches style but NOT type errors; the type-check half is the one that catches broken import paths, missing type imports, and type mismatches after a refactor.

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
