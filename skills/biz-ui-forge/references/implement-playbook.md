# Implement Playbook

Use this playbook whenever a visual reference must become real MUI code.

## Role

Act like a senior frontend developer working inside an existing codebase:
- preserve logic
- understand ownership of UI across the component tree
- reuse existing primitives
- produce code that looks native to the repo

## Inputs accepted

- HTML mockup
- screenshot or image
- Figma URL or exported frame
- requirement text plus an existing component path

## Thinking requirement

At every numbered step below, use `mcp__modelcontextprotocol-servers-sequentialthinking__sequentialthinking` to reason through your decisions before acting. Do not jump from reading to coding — think first, then implement. This applies especially to:
- Zone classification (app-shell vs page-specific)
- File ownership tracing (which file renders which zone)
- Phasing decisions (how to split work)
- Per-zone MUI translation (CSS vars → theme tokens, HTML structure → MUI components)

## Workflow

1. Identify the visual source.
   - HTML: parse structure, spacing, classes, and inline styles.
   - Screenshot: explicitly describe what is visible before coding.
   - Figma: inspect frame structure, spacing, alignment, and states.

2. Build a zone map.
   For every visible area, identify:
   - zone name
   - elements inside it
   - layout direction
   - density and spacing
   - interactions and states
   - responsive behavior

3. Classify each zone as **app-shell** or **page-specific**.

   App-shell zones are owned by the layout and already exist in the codebase:
   - sidebar / navigation rail
   - topbar / app header
   - breadcrumb bar (unless breadcrumb content is page-specific)
   - global search, notifications, user menu

   **Skip app-shell zones entirely.** Do not re-implement them. Only note if the mockup shows a shell variant that differs from the current app (e.g., a collapsed sidebar state) — flag it as a separate follow-up, do not inline it into the page implementation.

4. Trace rendering ownership.
   Do not assume the parent page renders everything.
   Inspect imported children and determine which file owns each zone.

   Use this checklist:
   - header / toolbar
   - filter bar
   - summary cards
   - data table shell
   - row or cell renderers
   - tabs / side panels
   - drawers / modals
   - empty / loading / error states

5. Build a file map.

   Example:
   - page shell → `orders-view.tsx`
   - metric cards → `orders-summary-cards.tsx`
   - row presentation → `orders-table-row.tsx`
   - status chip → `status-badge.tsx`

6. Assess mockup size and decide phasing.

   Count page-specific zones from step 2. If there are **6 or fewer**, implement in a single pass. If there are **7 or more**, split into phases using this priority order:

   **Phase 1 — Structure & Primary Content**
   1. Page header (title, status, actions)
   2. Lifecycle / stepper / progress indicators
   3. Tab bar / navigation within the page
   4. Primary tab content (the tab shown by default)

   **Phase 2 — Secondary Content**
   5. Secondary tab content (remaining tabs)
   6. Summary / metric tiles
   7. Detail field grids

   **Phase 3 — Overlays & Interactions**
   8. Modals / drawers
   9. Edit forms
   10. Interactive behaviors (search, filters, sorting)

   After each phase, emit a **zone progress checklist** (see "Progress tracking" below) so follow-up runs can resume.

7. Decide scope per phase.
   - If one file truly owns the visible change, update that file.
   - If child components own visible zones, update them too.
   - If shared components are used in many places, keep the change safe and scoped.

8. Implement.
   For each affected file in the current phase:
   - keep data flow and handlers intact
   - preserve hook order and naming conventions
   - replace JSX layout and styling to match the visual reference
   - use semantic theme tokens
   - remove unused imports created by the refactor
   - **complete each zone fully before moving to the next** — a half-implemented zone is worse than a missing one

9. Verify cross-file alignment.
   - parent props still match child props
   - exports/imports still resolve
   - loading, empty, error, hover, focus, and disabled states still exist
   - visual zones in the mockup all exist in code

## Progress tracking

After implementation (whether single-pass or phased), emit a zone progress checklist in this format:

```
## Zone Progress — [Feature Name]
| Zone | Status | File(s) | Notes |
|------|--------|---------|-------|
| Page header | ✅ Done | detail-view.tsx | — |
| Lifecycle stepper | ✅ Done | lifecycle-stepper.tsx | — |
| Tab bar | ✅ Done | detail-view.tsx | — |
| Overview tab | ✅ Done | overview-tab.tsx | — |
| Lines tab | ⬜ Pending | — | Phase 2 |
| Activity tab | ⬜ Pending | — | Phase 2 |
| Edit modal | ⬜ Pending | — | Phase 3 |
| Lines modal | ⬜ Pending | — | Phase 3 |
```

Save this checklist to `docs/design/[feature]-zone-progress.md`.

On follow-up runs, **read the zone progress file first**. Resume from the first ⬜ Pending zone. Do not re-implement ✅ Done zones unless the user explicitly asks for changes.

## Hard rules

- The parent file is not automatically the sole implementation target.
- If a child component owns a visible zone, change that child component.
- If a parent needs to pass new display props to a child, update both sides.
- Do not claim full implementation if child-owned zones remain unchanged.
- Do not invent data that is absent from types, props, or queries.

## Output pattern

Use this structure:

1. Context summary
2. Zone map
3. File ownership map
4. Implementation plan
5. Updated code
6. Verification notes
7. Data gaps or follow-ups
