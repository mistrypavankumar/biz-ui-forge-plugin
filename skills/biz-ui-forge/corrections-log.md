# Biz UI Forge — Corrections Log

Raw corrections are auto-captured by the hook into `corrections-log.jsonl`. This file is the **structured, human-readable** version where Claude logs analyzed corrections with root cause and correct behavior.

## How this works

1. **Hook** (`detect-corrections.sh`) catches correction-like messages and appends raw text to `corrections-log.jsonl`
2. **Claude** analyzes the correction, identifies root cause, and logs a structured entry here
3. **Periodic review** — user says "review corrections" or "improve the skill" to trigger promotion
4. **Promotion** — repeated corrections (count >= 2) get distilled into `learned-rules.md`

---

## Corrections

### STYLE-002 — Verbose JSDoc blocks and explanatory prose comments despite LR-020
- **Date**: 2026-04-17
- **Mode**: implement (ADR-013 frontend wiring)
- **What happened**: In `apps/scm/src/app/api/auth/chat-token/route.ts` and `packages/ui/src/components/chat-widget/use-multi-chat.ts` I wrote full JSDoc blocks like `/** * POST /api/auth/chat-token * * Issues a short-lived token for direct browser-to-Daxbot streaming (ADR-013). The browser uses this token to bypass the Lambda proxy on the streaming message endpoint only, so SSE chunks reach the UI incrementally. */` and multi-line `/** Direct Daxbot ELB base URL used for the streaming message POST (ADR-013). When set, browser streams directly from the ELB instead of via the Lambda proxy, delivering SSE tokens incrementally. Falls back to the proxy on any failure. Defaults to `process.env.NEXT_PUBLIC_DAXBOT_STREAM_URL`. */` option docs. These read like generated reference docs — a human developer writing the same code would have written zero or one-line comments.
- **User correction**: `--learn that when writting code don't write comments like ai, it should be like a human, so that it looks like written by developer`
- **Root cause**: `style-drift` — LR-020 already covers one-liners, but I treated JSDoc/block comments as exempt ("documenting an exported symbol is different"). The user's rule applies to all comment forms, not just `//`.
- **Correct behavior**: Strip verbose JSDoc on internal route handlers and option interfaces. When a symbol genuinely needs API docs (public shared library export), keep it to one short line — no multi-paragraph descriptions, no restating what the signature already says, no "when set, ..." explanations, no "Defaults to X" redundancies (TypeScript's default-value shows that). A fellow developer writes `// fetch once, cache until 30s pre-expiry` not four lines of prose.
- **Count**: 1
- **Status**: active

### AMP-003 — Replaced triple-slash type reference with runtime import that esbuild can't bundle
- **Date**: 2026-04-17
- **Mode**: amplify (fix-sandbox)
- **What happened**: In `amplify/functions/daxbot-readstream/handler.ts`, the original `/// <reference types="aws-lambda" />` directive was replaced with `import 'aws-lambda'` after an ESLint rule (`@typescript-eslint/triple-slash-reference`) flagged it. Both forms satisfied the IDE's TypeScript language server and cleared the ESLint warning. However, `aws-lambda` is the `@types/aws-lambda` DefinitelyTyped package — it contains **only** `.d.ts` files and no runtime JavaScript module. When `ampx sandbox` (or `ampx sandbox delete`) invoked esbuild to bundle the handler, esbuild tried to resolve `aws-lambda` as a real CommonJS/ESM module and failed with `Could not resolve "aws-lambda"`. This blocked every sandbox operation, including teardown.
- **User correction**: Pasted the esbuild error + CDK assembly failure from `ampx sandbox delete`.
- **Root cause**: `assumption-error` — trusted the ESLint rule's suggestion without distinguishing runtime-module imports from types-only package references. `@types/*` packages can be referenced via `/// <reference types>` or via `import type { ... } from 'aws-lambda'` (for named type imports, because `import type` is erased at emit). A bare `import 'aws-lambda'` for side-effect becomes a runtime import at bundle time and fails. Also — the quality gate for amplify code should have been `ampx sandbox --once`, not IDE diagnostics, since only the bundler surfaces this class of error (AMP-001 hit the same "IDE says OK, ampx fails" pattern).
- **Correct behavior**:
  1. For types-only packages referenced purely for ambient globals (like `awslambda`), use `/// <reference types="X" />` with an inline `// eslint-disable-next-line @typescript-eslint/triple-slash-reference` comment.
  2. For types-only packages referenced for named types, use `import type { Foo } from 'X'` — this is erased at emit.
  3. NEVER use a bare `import 'X'` (side-effect import) for a types-only package — esbuild/Node will try to resolve it as runtime JS and fail.
  4. For any amplify code change, run `ampx sandbox --once` (or rely on the running watcher's next deploy cycle) as the authoritative check. IDE diagnostics don't exercise the bundler.
- **Count**: 1
- **Status**: active

### AMP-002 — Leaked skill-internal paths into user-facing documentation
- **Date**: 2026-04-17
- **Mode**: amplify (documentation)
- **What happened**: While writing ADR-013 (docs/adr/013-amplify-gen2-daxbot-readstream.md), I referenced `.claude/skills/biz-ui-forge/references/amplify-playbook.md` in both the Consequences section ("Mitigated by the references/amplify-playbook.md in the biz-ui-forge skill...") and the References section. ADRs are human-facing architecture records that travel with the repo and get reviewed by people who don't use Claude Code; they should never reference skill-internal paths under `.claude/skills/`.
- **User correction**: "no need to add in the document related to skills"
- **Root cause**: `framework-leak` — leaked the skill's tooling vocabulary and file paths into a user-facing artifact. The playbook is an agent-facing operational doc; referencing it in an ADR implies the reader has access to that tooling.
- **Correct behavior**: Keep skill-internal references (anything under `.claude/`, references to "the biz-ui-forge skill", "the playbook", etc.) out of user-facing artifacts: ADRs, READMEs, design docs, CLAUDE.md top-level references, `apps/*/README.md`, PR descriptions, commit messages. When an ADR needs an operational runbook, point at a repo-root-visible doc like `amplify/README.md` or `docs/<feature>.md` — never at `.claude/skills/*`.
- **Count**: 1
- **Status**: active

### AMP-001 — Interface without index signature fails `HttpResponseStream.from` TS2345
- **Date**: 2026-04-17
- **Mode**: amplify (fix-sandbox)
- **What happened**: In `amplify/functions/daxbot-readstream/handler.ts`, I declared `interface ResponseMeta { statusCode: number; headers?: ... }` and passed it to `awslambda.HttpResponseStream.from(stream, meta)`. `@types/aws-lambda` declares that method's second parameter as `Record<string, unknown>`. Even though the literal object is structurally compatible, TypeScript rejects an interface assignment to `Record<string, unknown>` unless the interface has an explicit **index signature**. IDE didn't catch it because amplify/ resolution was flaky; `ampx sandbox`'s own TS validation caught it during deploy.
- **User correction**: `[ERROR] [SyntaxError] TypeScript validation check failed. ... handler.ts:129:52 - error TS2345: Argument of type 'ResponseMeta' is not assignable to parameter of type 'Record<string, unknown>'. Index signature for type 'string' is missing in type 'ResponseMeta'.`
- **Root cause**: `assumption-error` — trusted IDE diagnostic silence instead of running the real build. When a third-party API types a parameter as `Record<string, unknown>`, passing a narrow interface requires either an explicit index signature or an intersection with `Record<string, unknown>`.
- **Correct behavior**: For any type that'll be passed to a `Record<string, unknown>`-typed parameter, declare it as an intersection: `type X = { ... } & Record<string, unknown>`. This adds the index signature without losing call-site type safety and without requiring casts. Don't declare as interface — interfaces can't easily acquire an index signature. Also: `ampx sandbox` runs its own TS validation on the amplify tree; run `ampx sandbox --once` before declaring any amplify TS change done. IDE diagnostics alone are insufficient.
- **Count**: 1
- **Status**: active

### IMPL-009 — File manager uploaded any type regardless of active tab
- **Date**: 2026-04-16
- **Mode**: fix
- **What happened**: The file manager modal had three upload entry points: the upload dialog, outer drag-and-drop on the wrapper, and the paste handler. Only the upload dialog filtered by `uploadType` (via react-dropzone `accept`). The wrapper's `handleDrop` and the paste listener passed files straight to `handleOnUpload` with no type check, so a user on the Files tab could drop or paste an image and it would upload. The empty-state pill row and `FilesDropStrip` hint text also advertised "PNG / JPG" as allowed for the Files tab, contradicting the real accept config.
- **User correction**: Screenshot + "in file only files can be uploaded and in images only images should be allowed".
- **Root cause**: `logic-destroyed` + `skipped-state` — type-filtering was bolted onto the dialog entry point only. Subsequent entry points (drop, paste) were added without re-applying the same filter, so the invariant "Files tab rejects images; Images tab rejects non-images" held only partially. Hint text drifted from the real accept config.
- **Correct behavior**: Enforce the type filter at the **single funnel** (`handleOnUpload`) so every entry point inherits the rule. Toast rejected counts. Keep all advertised hints (drop-strip copy, empty-state pills, filter chips) in sync with the actual accept config — if images are rejected in Files mode, don't render an "Images" filter chip or a PNG/JPG pill there.
- **Count**: 1
- **Status**: active

### IMPL-008 — Drop handlers scoped wrong / child stopPropagation blocks parent reset
- **Date**: 2026-04-16 (two rounds: strip-only scope, then child-swallowed drop)
- **Mode**: implement, fix
- **What happened**: Two related bugs in the same feature. **Round 1**: Wired drag/drop only on the small dashed `FilesDropStrip` component. That strip only renders when files already exist, so empty state had no drop target. **Round 2**: After moving drop handlers to the outer wrapper, the child `FilesDropStrip` still had its own `onDrop` with `e.stopPropagation()`. When user dropped on the strip, files uploaded but the outer wrapper's `handleDrop` never fired, so `isDragOver` stayed `true` and the "Release to upload" overlay + dashed border persisted after drop completed.
- **User correction**: (1) Screenshot of empty state + "drag and drop is not working". (2) Screenshot of populated table with persistent drop overlay + "after drop still i can see this".
- **Root cause**: `assumption-error` + `logic-destroyed` — when a section has layered drop targets (outer card + inner strip), EITHER the outer owns all handling OR the inner forwards events, never both. Having both with `stopPropagation` on the inner creates a dead zone where drops succeed but UI state doesn't reset.
- **Correct behavior**: When a container is the drop zone, ALL drag/drop handlers live on that container. Inner visual cues (strip, overlay, placeholder) must NOT have their own `onDragOver`/`onDrop` — or if they do, must NOT call `stopPropagation`. Belt-and-suspenders: define a `resetDragState()` helper and call it from both `handleDrop` AND the start of the upload pipeline, so state clears even if the drop event path is interrupted. Test: drop on empty state, drop on populated area, drop on every inner visible element.
- **Count**: 2
- **Status**: active

### IMPL-007 — Guessed react-icons export name casing (HiSquares2x2 vs HiSquares2X2)
- **Date**: 2026-04-16
- **Mode**: implement
- **What happened**: When implementing the Files section, imported `HiSquares2x2` from `react-icons/hi2`. The actual export is `HiSquares2X2` (capital X). The build failed at Turbopack transform time — TypeScript didn't catch it because node resolution succeeded but the named export was missing at runtime. The editor's IntelliSense for react-icons doesn't preview exports without typing, so guessing from memory is error-prone.
- **User correction**: Build error: "Export HiSquares2x2 doesn't exist in target module. Did you mean to import HiSquares2X2?"
- **Root cause**: `assumption-error` — guessed the casing convention without verifying. react-icons uses an inconsistent casing rule: digits followed by letters are often capitalized (e.g., `HiSquares2X2`, `HiBars3CenterLeft`, `HiOutlineSquares2X2`). Cannot rely on kebab→camel intuition.
- **Correct behavior**: Before using any react-icon that contains digits (`2x2`, `3d`, `4k`, etc.), verify the exact export name by grep against existing imports in the codebase, or check `node_modules/react-icons/<pack>/index.d.ts` if unsure. When in doubt, use a digit-free alternative (e.g., `LuLayoutGrid` instead of `HiSquares2X2`).
- **Count**: 1
- **Status**: active

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
