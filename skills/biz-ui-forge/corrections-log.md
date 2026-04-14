# Biz UI Forge — Corrections Log

Raw corrections are auto-captured by the hook into `corrections-log.jsonl`. This file is the **structured, human-readable** version where Claude logs analyzed corrections with root cause and correct behavior.

## How this works

1. **Hook** (`detect-corrections.sh`) catches correction-like messages and appends raw text to `corrections-log.jsonl`
2. **Claude** analyzes the correction, identifies root cause, and logs a structured entry here
3. **Periodic review** — user says "review corrections" or "improve the skill" to trigger promotion
4. **Promotion** — repeated corrections (count >= 2) get distilled into `learned-rules.md`

---

## Corrections

### IMPL-006 — Used Iconify strings instead of react-icons
- **Date**: 2026-04-10
- **Mode**: fix
- **What happened**: When creating the service-policy-assignment list view and modal, used Iconify string identifiers (`"mingcute:document-fill"`, `"solar:settings-bold-duotone"`, `"solar:target-bold-duotone"`) for icons instead of react-icons components. LR-006 already required using react-icons, but the rule was not specific enough about prohibiting Iconify.
- **User correction**: "use react icons, also i have mentioned in learn but still why using iconify"
- **Root cause**: `style-drift` — Defaulted to Iconify strings (which some shared components accept) instead of react-icons JSX components. LR-006 said "use varied react-icons families" but didn't explicitly prohibit Iconify as an alternative.
- **Correct behavior**: Always use react-icons components. For component props that accept both `iconName` (string) and `icon` (ReactNode), always use the `icon` prop with a react-icons component. Zero Iconify strings in new code.
- **Count**: 1
- **Status**: promoted → LR-012

### IMPL-005 — Replaced AG Grid with custom MUI table when implementing mockup
- **Date**: 2026-04-09
- **Mode**: implement
- **What happened**: When implementing the "Assigned Users" mockup for the role detail users tab, replaced the existing AG Grid table with a custom MUI Box-based table to match the mockup's visual style. The user corrected this — AG Grid is the standard table component in this codebase.
- **User correction**: "use aggrid table"
- **Root cause**: `assumption-error` — Assumed the mockup's clean table look required a custom MUI table. Should have kept AG Grid and used custom cellRenderers to achieve the same visual style. AG Grid is the mandatory table component in this project.
- **Correct behavior**: When implementing a table mockup, always use AG Grid with custom cellRenderers to match the visual design. Never replace AG Grid with a custom MUI table. The mockup defines the look; AG Grid + cellRenderers is the implementation tool.
- **Count**: 1
- **Status**: promoted → LR-022

<!-- 
Add new entries at the top:

### [SHORT_ID] — Brief title
- **Date**: YYYY-MM-DD
- **Mode**: mockup | implement | fix | audit | redesign | build
- **What happened**: What Claude did wrong
- **User correction**: What the user said
- **Root cause**: Category + why it happened
- **Correct behavior**: What should have been done
- **Count**: N
- **Status**: active | promoted | obsolete
-->

### IMPL-004 — Duplicated UI block instead of extracting a shared component
- **Date**: 2026-04-03
- **Mode**: implement
- **What happened**: When creating `ProfileBusinessUnits` (modeled after `ProfileRoles`), first copy-pasted only the 60-line user identity banner as a `UserIdentityBanner` component — but missed the bigger picture: the entire assign modal pattern (CreateEditDialogModal + banner + instruction + form slot) was identical. User had to correct twice — first for the banner, then for the full modal.
- **User correction**: (1) "why created again … create component of that and use that everywhere" (2) "why you created only userIdentityBanner, create separate assign modal which should be reusable and then use that accordingly in both"
- **Root cause**: `assumption-error` — Extracted the smallest visible duplication (banner) instead of stepping back to identify the full scope of the duplicated pattern. When two components share an identical modal structure that differs only in title/subtitle/instruction/form-content, the entire modal is the reusable unit, not just one inner zone.
- **Correct behavior**: When told "same as X", identify the **largest reusable boundary** — not just the first obvious block. Ask: "what is the full repeated structure, and what are the only things that vary?" Extract the full pattern as a component with props for the varying parts. In this case: `AssignModal` with props for `title`, `subTitle`, `instruction`, and `children` (the form).
- **Count**: 2
- **Status**: promoted → LR-021

### IMPL-003 — Created new component instead of following existing pattern when told "same as X"
- **Date**: 2026-04-03
- **Mode**: fix
- **What happened**: User asked for BusinessUnit + button to open create modal "same as we did for users". Instead of reading how Users modal is wired in global-modals (self-contained, owns its own form state), created a separate wrapper component and later put inline form state in global-modals. The existing `RoleModal` and `UserNewEditModal` are self-contained — they own their form state, mutations, and submit logic internally. BusinessUnitModal should have followed the same pattern.
- **User correction**: "no need to create a new we need to use global-modal" + "it did same but created new instead of seeing users modal how it is implemented"
- **Root cause**: `assumption-error` — Did not read the reference implementation (Users/Roles modal) before building. When user says "same as X", the first step must be reading X's implementation, not assuming the pattern.
- **Correct behavior**: When told "same as X", always read X's implementation first. For global-modals integration, modals must be self-contained (own form state, mutations, submit logic). The parent (global-modals) only passes `open`, `onCloseAction`, `actionType`, `title`.
- **Count**: 1
- **Status**: active

### TS-001 — TypeScript errors left after UI implementation
- **Date**: 2026-04-02
- **Mode**: fix
- **What happened**: After creating/modifying UI components (change-log-ag-grid-table.tsx and user-profile-view.tsx), TypeScript errors were left unfixed — AG Grid `cellStyle` type widening caused `CellStyle` incompatibility, and an unused `ActionButton` import remained.
- **User correction**: "also learn while creating any ui make sure all ts fixed"
- **Root cause**: `incomplete-phase` — implemented the UI changes but did not run type-check before presenting the work as complete. User had to report the TS errors.
- **Correct behavior**: After any UI creation or modification, always run `pnpm --filter <pkg> type-check` on affected packages and fix all errors before considering the work done. Common AG Grid pitfall: `cellStyle` objects in array literals need `as CellStyle` assertions to prevent TypeScript union widening.
- **Count**: 1
- **Status**: promoted → LR-003

### IMPL-002 — Incomplete mockup implementation: missed visual details across multiple zones
- **Date**: 2026-04-02
- **Mode**: implement
- **What happened**: When implementing the v2 profile mockup, multiple visual details were wrong: role names rendered in ALL CAPS instead of title case, app chips stacked vertically instead of inline, chip text was uppercase, role badge missing star icon, count badge positioned wrong, buttons used wrong variant/icon, table had extra left eye column not in mockup, header had icon box not in mockup.
- **User correction**: "this is what we have but i want exact same as in the mockup" + "learn this that when i ask to implement mockup then always implement whatever is present in mockup"
- **Root cause**: `style-drift` — implemented structural layout correctly but didn't pixel-diff every visual element (text casing, icon choices, chip styles, layout direction, button variants, badge placement) against the mockup. Treated the mockup as a rough guide instead of an exact spec.
- **Correct behavior**: Before submitting, visually diff EVERY element in the mockup against the code: text casing/transforms, icon choices, chip/badge styles, layout direction (row vs wrap), spacing, button variants (outlined vs contained), color tokens, column layout. If the mockup shows title-case but data is uppercase, add a formatter. If mockup shows inline chips, don't allow wrapping. Match it exactly.
- **Count**: 3
- **Status**: promoted → LR-002

### STYLE-001 — Failed to auto-format files after editing, causing import order and spacing lint errors
- **Date**: 2026-04-02
- **Mode**: fix
- **What happened**: After editing user-profile-view.tsx, manually rearranged imports to fix lint errors but got the ordering wrong multiple times (type vs value import order, spacing between groups, member sort inside named imports). Each manual attempt introduced new lint errors.
- **User correction**: "after writing code make sure to format code using eslint, that too only on files which you touch"
- **Root cause**: `style-drift` — tried to manually match ESLint import ordering rules instead of running the linter's auto-fix.
- **Correct behavior**: After every file edit, run `pnpm eslint --fix <touched-file>` to let ESLint handle import sorting, spacing, and formatting automatically. Only target the specific files you changed.
- **Count**: 1
- **Status**: promoted → LR-001

### IMPL-001 — Kept wrapper modal that conflicts with mockup layout
- **Date**: 2026-04-01
- **Mode**: implement
- **What happened**: Used CreateEditDialogModal as the wrapper when implementing the v2-hero mockup. This added its own header bar (title + close), footer, and DialogContent padding — creating a double-header that doesn't match the mockup's integrated banner design.
- **User correction**: "still not same as mockup avoid create-edit-dialog modal"
- **Root cause**: `assumption-error` — assumed the existing modal wrapper should always be preserved. When a mockup designs its own header/close/footer, the wrapper's chrome conflicts.
- **Correct behavior**: When a mockup has its own header/banner/close/footer that differs structurally from CreateEditDialogModal, use a raw MUI Dialog instead. Replicate permission and loading logic manually.
- **Count**: 1
- **Status**: active
