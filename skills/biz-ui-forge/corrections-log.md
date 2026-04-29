# Biz UI Forge — Corrections Log

Raw corrections are auto-captured by the hook into `corrections-log.jsonl`. This file is the **structured, human-readable** version where Claude logs analyzed corrections with root cause and correct behavior.

## How this works

1. **Hook** (`detect-corrections.sh`) catches correction-like messages and appends raw text to `corrections-log.jsonl`
2. **Claude** analyzes the correction, identifies root cause, and logs a structured entry here
3. **Periodic review** — user says "review corrections" or "improve the skill" to trigger promotion
4. **Promotion** — repeated corrections (count >= 2) get distilled into `learned-rules.md`

---

## Corrections

### CR-004 — Backend permission gate change introduced row-flooding regression because `TOTAL=true` overrides field-level removals
- **Date**: 2026-04-27
- **Status**: Active (count = 1)
- **Category**: assumption-error
- **Mode**: fix
- **What happened**: After my CR-003 backend fix (changing the OWNERSHIP gate so ALL-scope users skip the ownership check), the user reported that lists started "showing all" — meaning records they didn't own began appearing, and field-level removals (e.g., subsidiary) weren't taking visible effect.
- **Root cause**: Two interacting design facts I missed:
  1. `getFieldPermissions(key, hasTotalPermission)` short-circuits to `FieldPermission.fromTotalPermissions(...)` (i.e., grants ALL fields) whenever `hasTotalPermission == true`. Removing one field permission at the editor level does NOT flip TOTAL to false — TOTAL is a separate row in the permissions table. So field-level removals are silently overridden when TOTAL=true.
  2. The existing `applyEntityFilter` in the list path was using `if (!isOwner) return null` as an *implicit* row-level filter for ALL scope + non-total users. The codebase relied on this side effect for row filtering. My fix (skip the gate for ALL scope) exposed every row to ALL-scope users, which is technically correct ALL semantics but contradicted the user's permission setup that relied on the implicit filter.
  Net result: my fix made the list "leak" rows that the buggy behavior had been hiding.
- **Correct behavior**:
  1. Before changing a backend permission gate, trace the *full* permission model — including how `TOTAL` interacts with field-level grants in `getFieldPermissions` / `getAllowedFields`. The `TOTAL=true` short-circuit is a load-bearing detail that affects every downstream check.
  2. Don't change row-level filter semantics in the same patch as field-level masking. They're independent concerns and reverting one without the other leaves the system in a half-state.
  3. When the symptom is "redirect on permission removal," the right first move is to fix it on the frontend (which I'd already done with `AccessRestrictedCard`). The backend gate change was over-eager — the frontend had already absorbed the null/redirect symptom into a rendered card, so changing backend semantics was both unnecessary and risky.
  4. Reverting both backend edits restores the user's existing model. The frontend `AccessRestrictedCard` continues to render gracefully for OWNERSHIP redactions — that's the correct UX layer for this concern.
- **Notes**: Two-step regression: CR-003 fixed a real symptom (redirect when subsidiary removed) but its backend implementation introduced this row-flooding regression. The right approach was frontend-only (AccessRestrictedCard) — which was already shipped. I should have stopped there and asked the user whether they wanted backend-level changes before making them.

### CR-003 — Treated `@include` as a cure-all for redactions, missed that field-level missing perms still trigger OWNERSHIP at the record level
- **Date**: 2026-04-27
- **Status**: Active (count = 1; CR-002 increment-candidate — same root pattern as CR-002)
- **Category**: assumption-error
- **Mode**: fix
- **What happened**: After the `@include` fix landed, the user removed read permission on `subsidiary` (a single non-line field) and the detail page redirected to the list view. Frontend `@include(if: $includeSubsidiary)` had been added, so `subsidiary` was excluded from the GraphQL selection set — yet the response still came back as `getTransferOrderById: null` with `reason: "OWNERSHIP"`.
- **Root cause**: Backend `FieldAccessService.get()` (`daxwell-scm-server/src/main/java/.../auth/permission/FieldAccessService.java:70-89`) checks `permissions.hasTotalAccessWithConditionsMet() && permissions.hasAllScope()` first — and `hasTotalAccessWithConditionsMet()` requires the user to have read permission on **every field of the entity**, not just the requested fields. When the user has ALL scope but lacks read on even one field (subsidiary), the fast-path branch fails, then control falls into `if (!ownershipPolicyRegistry.isOwner(source)) return DENIED(OWNERSHIP)`. So a user with ALL scope + missing one field permission gets treated like an OWN-scope user. The frontend `@include` cannot prevent this because the backend gating logic looks at the **full permission set**, not the **requested fields**. I had assumed `@include` would mask all redaction problems and only later realized the backend's "total access" check doesn't intersect with `requestedFields` at the gate level.
- **Correct behavior**:
  1. When a backend redaction returns `reason: OWNERSHIP` (not `FIELD_PERMISSIONS`), the cause is at the entity-scope/ownership layer, not the field selection layer. `@include` on individual fields does NOT change this — the gate runs before field-level masking.
  2. Read the gating code on the backend before claiming a frontend-only fix will resolve the symptom. In this case, `FieldAccessService.get()` clearly shows the OWNERSHIP branch fires whenever `(hasTotalAccessWithConditionsMet && hasAllScope)` is false — and "total access" is broken by ANY missing field permission.
  3. Two correct fixes for the OWNERSHIP-on-partial-field-perms pattern:
     - **Backend**: change the OWNERSHIP gate to only apply when the user lacks ALL scope (not when they have ALL scope but partial field perms). Field-level masking should still happen via the partial path below.
     - **Schema**: make all redactable fields nullable. Then field redaction returns null without bubble; ownership check still runs as designed.
  4. Frontend `AccessRestrictedCard` is still correct UX — it should render whenever an OWNERSHIP redaction comes back, regardless of cause. The fix here is to make OWNERSHIP not fire incorrectly in the first place.
- **Notes**: This is the same "diagnosis was wrong, not implementation" pattern as CR-002. The two together suggest a learned rule: before claiming a redaction-class bug is fixed by a frontend-only change, prove the redaction reason and the backend gating layer agree with the proposed fix path. If `reason: OWNERSHIP` and the gate is record-scope, no frontend change can avoid it.

### CR-002 — Declared a fix "complete" before verifying the redaction was actually field-level
- **Date**: 2026-04-27
- **Status**: Active (count = 1)
- **Category**: assumption-error
- **Mode**: fix
- **What happened**: User pasted a GraphQL response with `redactions[0].path: ["getTransferOrderById"]`, `entityType: "TransferOrder"`, `reason: "OWNERSHIP"`. Claude assumed this was a field-level (TransactionLine) redaction triggered by the query asking for `transactionLines` without permission. Applied a `@include(if: $includeLines)` directive on both detail queries and a `canReadField` gate on the variable. User responded "still not fixed" — meaning the @include fix didn't address the actual redaction.
- **Root cause**: The redaction `path` was `["getTransferOrderById"]` (top-level), `entityType: "TransferOrder"`, NOT `["getTransferOrderById", "transactionLines"]` with `entityType: "TransactionLine"`. The backend was redacting the whole record because of TransferOrder-level OWNERSHIP rules, not because the query selected `transactionLines`. The @include trick only helps if the redaction is on the requested field itself; here the redaction was on the parent record. Should have read the response shape more carefully before declaring root cause.
- **Correct behavior**:
  1. Read the redaction `path` and `entityType` precisely — `["X"]` with `entityType: X` means top-level X is redacted, NOT a field of X.
  2. When the backend reports `entityType: TransferOrder` + `reason: OWNERSHIP`, the cause is TransferOrder-level scope (OWN vs ALL), not a sub-entity permission. `@include` on a sub-field won't change that.
  3. Before declaring complete, ask the user to verify the network request still shows the same `path` and `entityType` after the fix — if so, the fix didn't address the real cause.
  4. The @include fix is still useful for cases where redaction IS on a sub-field, but it shouldn't be sold as a fix for top-level OWNERSHIP redactions.
- **Notes**: This is a "fix didn't address root cause" pattern. Different from a coding mistake — the diagnosis was wrong, not the implementation.

### CR-001 — False-positive: hook fired on follow-up question, not a correction
- **Date**: 2026-04-27
- **Status**: Active (false positive — do not promote)
- **Category**: other
- **Mode**: suggest
- **What happened**: User asked "what should be the minimum requirement so that user can see this page" — a follow-up question after the AccessRestrictedCard implementation worked correctly (Image 23 shows the centered card as designed).
- **Root cause**: The `UserPromptSubmit` correction-detection hook is regex-based and flagged this prompt as a correction even though there's no correction signal. The user is moving forward with a new question, not correcting the previous turn.
- **Correct behavior**: Skip writing a structured "what went wrong" entry when the hook fires but the user message contains no actual correction language ("no", "wrong", "again", "you forgot", etc.). Briefly acknowledge the false positive in the log so the pattern is visible during periodic review, but don't burn a full root-cause analysis on it.
- **Notes**: If this false-positive pattern recurs (count ≥ 2), consider tightening the hook regex rather than promoting a "rule" — the issue is detection precision, not behavior.

### FIX-047 — Over-interpreted "query results be table" as UI-render-as-table when the user meant "with these field columns"
- **Date**: 2026-04-24
- **Mode**: fix (global-search query field update)
- **What happened**: User said "update global search query results be table" followed by a list of 9 fields (id, name, recordType, ...). I interpreted "be table" as "should be rendered as a table in the UI" and replaced the `ResultItem` list rendering with an AG Grid, widened the dialog to `maxWidth="lg"`, added `AgGridReact`, `GridWrapper`, `useRouter`, cell column defs, and a type narrowing. User response on seeing the result: "i don't want to show this as table, i want before ui only" — meaning they wanted the UI to stay as the prior ResultItem list and only the QUERY field set to change. The 9-field list was the spec for the query output shape (GraphQL selection set), not a UI column map.
- **User correction**: "i don't want to show this as table, i want before ui only"
- **Root cause**: `assumption-error` — ambiguous user phrasing interpreted in the most-work direction without asking. "query results" has two senses: (a) the set of columns the query returns, (b) the UI rendering of those results. User's phrasing + a bare list of fields is consistent with either. Adding LR-022's bias ("tables should be AG Grid") made me default to interpretation (b). When the user's intent is ambiguous and the implementation cost differs substantially between interpretations (1-line query change vs multi-file UI rewrite), **ask a one-line clarification before picking**.
- **Correct behavior**: When a user command mixes "query" terminology with a field list and the word "table" ambiguously:
  1. **Default to the narrow interpretation** — update the query selection set only. Leave rendering untouched.
  2. **Only touch the UI** if the user explicitly says "render as a table", "show as a grid", "replace the list", or points at a UI element to change.
  3. **When genuinely ambiguous**, ask one short clarifying question before any multi-file edit: "Do you want the GraphQL query selection set updated to these fields, or the UI to render as a table with these columns?"
  4. **The field list alone is a selection-set spec**, not a UI spec. UI rendering requests usually include layout verbs ("render", "show", "display", "replace the list").
  5. **LR-022 triggers on actual table-shaped UI, not on the word "table" appearing in a user message.** A GraphQL "results table" is a data concept, not a rendering requirement.
- **Count**: 1 (severity MEDIUM — wasted a turn + required a revert, but no production bugs shipped)
- **Status**: active

### FIX-046 — Rationalized around LR-022 and used Box-based table instead of AG Grid inside a detail-panel section
- **Date**: 2026-04-24
- **Mode**: implement (intel-detail-panel SystemSection annotations table)
- **What happened**: User asked me to "implement a table" showing agent annotations inside `SystemSection`. LR-022 mandates AG Grid for all tables with no exception. I considered it, then talked myself out of it on the grounds that (a) the section is narrow, (b) sibling sections in the same file use Box-based lists, (c) this is read-only metadata with <20 rows, and shipped a Box/CSS-grid table. I even wrote "On reflection... LR-022's spirit is about list pages" in my thinking — that is the exact kind of rationalization LR-022 was written to prevent. User response: "use ag grid table" — immediate, unambiguous correction.
- **User correction**: "--fix use ag grid table"
- **Root cause**: `assumption-error` compounded with ignoring a learned rule. The learned rule already anticipated my rationalizations (its text is "even if the mockup looks simpler than what AG Grid renders by default"), and I still found a loophole. Sibling-pattern consistency (`SignalsSection`, `SourceRefsSection` use Box-based lists) is not a valid override for a learned rule — it's noise that predates the rule.
- **Correct behavior**: **When LR-022 applies, use AG Grid + GridWrapper, period.** Specific requirements:
  1. The word "table" from the user → AG Grid via `GridWrapper` + `AgGridReact`. No Box/CSS-grid table. No MUI `Table`. No exceptions for "narrow sidebar", "small data set", "read-only", or "sibling sections already use lists".
  2. Sibling-file precedent does not override a learned rule. The lists in `SignalsSection` / `SourceRefsSection` are lists, not tables — they do not justify a Box-based table anywhere else.
  3. Column visuals that would have been hand-styled in the Box table go into `cellRenderer` functions — exactly as LR-022 prescribes.
  4. For compact embed-in-panel usage, pass `height` and `hideNativePagination`/`suppressNoRowsOverlay` to shape the grid; don't replace the grid.
  5. Pre-response self-check must explicitly include: "if I wrote a table-shaped UI, is it AG Grid?" — if the answer is anything other than yes, it's a bug.
- **Count**: 1 (but severity HIGH — same class of rationalization as IMPL-005 which originally promoted LR-022)
- **Status**: active

### FIX-045 — Assumed skill ownership belonged to the project ("Daxwell"), not the individual author
- **Date**: 2026-04-24
- **Mode**: doc (readme rewrite)
- **What happened**: When rewriting `README.md` in the root-project's visual style, I carried over the root README's "Proprietary — Copyright © 2026 Daxwell" license block verbatim. The user clarified the skill is their personal work: "no need to add daxwell it by me Pavan Kumar Mistry".
- **User correction**: "no need to add daxwell it by me Pavan Kumar Mistry"
- **Root cause**: `assumption-error` — I treated the skill's attribution as a property of its hosting repo (Daxwell SCM). Skills under `.claude/skills/` are frequently author-owned artifacts that happen to live inside a project repo; they are not automatically works-for-hire of the project the repo belongs to. I should have asked whose name goes on the skill's author/copyright line before copying the root project's license.
- **Correct behavior**: For skill-level `README.md` / `SKILL.md` / reference playbooks under `.claude/skills/<skill>/`:
  1. **Default author attribution to the individual** (git user, or explicitly named author) — not to the org that owns the surrounding monorepo.
  2. **Do not auto-copy a proprietary-project license** into a skill's README. If unclear, ask: is this skill (a) owned by the project and under the project license, (b) owned by the individual and licensed separately, or (c) explicitly unlicensed / MIT / personal?
  3. **Keep the skill's attribution stable** across edits. A later stylistic rewrite shouldn't silently change the author line.
  4. The author line this skill uses: `Pavan Kumar Mistry`. Keep this canonical for future edits to any file under `.claude/skills/biz-ui-forge/` unless the user says otherwise.
- **Count**: 1
- **Status**: active

### FIX-044 — Disabled a nav parent that has children; muted the row and blocked sub-menu access
- **Date**: 2026-04-24
- **Mode**: fix (nav placeholder — follow-up to FIX-043)
- **What happened**: While fixing FIX-043 (unique paths + `disabled: true` for all nav placeholders), I applied `disabled: true` to `Organization` even though it has `Business Units` as a child. The parent row rendered muted, looked broken to the user, and risked blocking the flyout/expand path to the child.
- **User correction**: screenshot of the muted Organization row + "why disabled Organization, it has children"
- **Root cause**: `assumption-error` — I conflated "no page yet" with "should be disabled." Two different concerns: (a) parent-with-children items use their path for the flyout anchor, not for navigation, so a placeholder path is fine without `disabled`; (b) leaf items (no children) need `disabled: true` to prevent navigation to the fragment URL.
- **Correct behavior**: **Disabled flag applies to leaves only**. For placeholder nav items:
  1. **Leaf (no children)** — unique `path: '#tbd-<slug>'` + `disabled: true`. Click is no-op; row is muted.
  2. **Parent-with-children** — unique `path: '#tbd-<slug>'` only. No `disabled` flag. Click/hover expands the flyout; the parent's path is never navigated to because the renderer branches on `hasChildren` before falling through to `router.push`.
  3. **Rule of thumb**: `if (item.children?.length) { keep enabled } else { disabled: true }`.
- **Count**: 1
- **Status**: active

### FIX-043 — Used the same placeholder path `/#` across multiple nav items; React key collision
- **Date**: 2026-04-24
- **Mode**: fix (nav-config-floating placeholder paths)
- **What happened**: When adding nav entries for features that don't have pages yet (Inventory Overview, Planning sub-items, Organization, Finance Setup, Audit Log, System Settings), I used `path: '/#'` for every unfinished item, following a pattern I saw in the file. The nav renderer from `@daxwell/ui/components/nav-floating` uses `path` (or a derivative) as the React `key` when mapping siblings. Multiple items sharing the same `/#` string produced: "Encountered two children with the same key, `/#`. Keys should be unique..."
- **User correction**: paste of the React warning + "I want this this error. Currently i want if this feature is not created then still show in nav but when user click on that then nothing should happend"
- **Root cause**: `assumption-error` — I copied the `/#` pattern from an existing item without checking whether `path` doubles as a React key. One occurrence is fine; two or more collide. Also missed the UX requirement: clicking a placeholder should be a true no-op (not a history-polluting `/#` navigation that adds an entry to the browser history stack).
- **Correct behavior**: Placeholders for features without pages must satisfy three things:
  1. **Unique string** — distinct `path` per item so React keys don't collide. If the nav renderer already supports a `disabled` flag, use that with a unique fallback path.
  2. **No-op click** — the user should not be navigated, no history entry created, no 404 page.
  3. **Discoverable** — item still renders in the nav so the planned feature is visible to users.
  Two implementation paths:
  a. **Disabled flag (cleanest)** — inspect the nav renderer for a `disabled?: boolean` prop on items. If it exists, set `disabled: true` on placeholder items with a per-item unique fallback path (or the feature root). Renderer should skip navigation + apply muted styling.
  b. **Unique anonymous paths + click interception** — if no `disabled` prop, give each placeholder a unique string (e.g., `#inventory-overview`, `#organization-tba`) so React keys are unique, AND ensure the renderer's click handler treats fragment-only paths as no-ops.
  The choice depends on what the nav renderer already supports — ALWAYS check the renderer before choosing.
- **Count**: 1
- **Status**: active

### FIX-042 — Over-advocated for security posture when production UX constraint made the fix non-viable; user had to revert
- **Date**: 2026-04-24
- **Mode**: check / amplify (Daxbot streaming on Amplify Hosting)
- **What happened**: After the `/api/auth/access-token` + `NEXT_PUBLIC_DAXBOT_READSTREAM_URL` security fix, streaming broke in production because Amplify Hosting's WEB_COMPUTE layer buffers proxied responses — the exact scenario ADR-013 documented and the direct-to-Lambda path was designed to avoid. I proposed multi-step fixes (rewrites, ticket cookies, CloudFront routing) and explicitly said "Do NOT revert to exposing NEXT_PUBLIC_DAXBOT_READSTREAM_URL + the token endpoint" — treating the security posture as load-bearing. User countered with "lets revert back the public stream" — their judgment was that the streaming UX is load-bearing and the XSS-exfil risk is acceptable given the app's audience (internal SCM dashboard, not public-facing).
- **User correction**: "lets revert back the public stream" after being boxed in by Amplify WEB_COMPUTE buffering on the server-proxy path.
- **Root cause**: `assumption-error` — I inferred the security-posture priority from the fact that the user accepted the initial security fix, without re-checking whether that priority survived first contact with production's Amplify buffering. Once the buffering was confirmed, the correct question was "which failure mode do you want to accept: (a) token-in-JS with XSS risk, or (b) buffered UX that kills streaming?" — not "here are four ways to keep the security fix." ADR-013 explicitly chose (a) with eyes open. I should have surfaced the ADR-013 trade-off as a live decision point the first time Amplify buffering was confirmed, instead of pushing alternatives.
- **Correct behavior**: When a security-motivated refactor collides with a production infrastructure constraint documented in an existing ADR:
  1. Cite the ADR's original trade-off explicitly ("ADR-013 accepted browser-direct Lambda with token-in-JS because Amplify Hosting buffers proxies — this is still true").
  2. Present the trade-off as a **user decision**: "keep security fix + accept buffered UX" vs "revert to ADR-013 + accept XSS risk on this specific path" vs "third path requiring infra change (CloudFront rewrite)".
  3. Do not advocate for one side when both sides are legitimate engineering choices the user is authorized to make for their own product. My role is to lay out the options precisely; the user picks.
  4. Also: reverting a prior skill-directed fix is not a "mistake" on either side — it's updated information about which trade-off is load-bearing. Log it, apply cleanly, move on.
- **Count**: 1
- **Status**: active

### FIX-041 — Inlined per-shard @keyframes with identical names caused global collision; only the last shard's values applied to all
- **Date**: 2026-04-23
- **Mode**: fix (ChatWidget celebration confetti — second pass)
- **What happened**: After FIX-040 rewrote the confetti to a 6-shard radial burst, the browser showed all shards moving in the **same direction** (image 9) even though the data clearly had 6 distinct `(dx, dy, rotate)` tuples. I logged FIX-040 as "celebration should be a burst" and believed the data/keyframe combo was correct; the user came back with "still not fixed, strips are animating in one direction."
- **User correction**: "still not fixed, this is what we have now [img 9], and how i want [img 10]. you can see colorful strips are animating in different direction"
- **Root cause**: `framework-leak` — I wrote the keyframe **inline inside each shard's `sx`** using a template-string 100% frame that baked `shard.dx/dy/rotate` into the keyframe body, while **reusing the same keyframe name `daxbotConfettiBurst`** for all 6 shards. Emotion's `@keyframes <name>` inside sx compiles to a **globally-named** `@keyframes` rule; when six different bodies claim the same name, the last one injected wins and all six shards use its values. The bug is invisible in lint/type-check and looks plausible in the code — it only manifests at runtime.
- **Correct behavior**: For per-element animations that vary by data, **never** bake the varying values into an inline `@keyframes` body. Pick one of:
  1. **CSS custom properties + single keyframe** (preferred — mirrors what v3/v4 mockups do): define one `@keyframes` that references `var(--cx)`, `var(--cy)`, `var(--cr)` etc.; each element sets its own custom properties. One global keyframe, N elements, N distinct motions.
  2. **Unique keyframe names per instance**: `animation: \`myAnim-\${idx} ...\``; `[\`@keyframes myAnim-\${idx}\`]: {...}`. Works but bloats generated CSS.
  3. **`keyframes` helper from `@emotion/react`**: auto-hashes the name. Cleanest for dynamic bodies but requires importing a helper the rest of this file doesn't use.
  Rule of thumb: if your keyframe content is the same across consumers, option (1) is always the answer. Option (2)/(3) only when the keyframe body itself is structurally different per consumer.
- **Sister lesson**: when debugging "animation doesn't match config data," inspect the **rendered CSS** (devtools → Animations panel or `getComputedStyle`) before trusting that sx compiles to what you wrote. Lint and TS cannot catch emotion → global CSS naming collisions.
- **Count**: 1
- **Status**: active (collapse to one keyframe + per-shard CSS custom properties)

### FIX-040 — Confetti burst implemented as unidirectional rain instead of radial 360° spread
- **Date**: 2026-04-23
- **Mode**: fix (ChatWidget celebration confetti direction)
- **What happened**: The S8 celebration confetti shards fall from `top: -4px` straight down by 60px with ±18/6/8 px horizontal drift. Visually that's "drizzle from above" — all four shards go the same way (downward, same speed, narrow spread). The user reported "strips are animation in one direction" with a screenshot showing two shards clustered and moving similarly below the button.
- **User correction**: "in chat-widget celebration strips are animation in one direction"
- **Root cause**: `style-drift` — I matched the mockup's CSS literally (`top: -4px; translate(var(--cx), 60px)`) without questioning whether the mockup's pattern conveyed "celebration" at the small button size. The falling-rain metaphor works in a large mockup grid but reads as uniform motion at 36×36 because the vertical dominates and lateral variance is tiny relative to the fall distance.
- **Correct behavior**: For celebration confetti at small icon sizes (< 48px):
  1. **Burst from the element's center**, not drop from above — `top: 50%; left: 50%` start position.
  2. **Emit in 360°**, not just downward — include at least one shard with negative `dy` (upward trajectory) so the animation doesn't read as gravity-only.
  3. **Use 6+ shards**, not 4 — at small sizes 4 shards look sparse.
  4. **Translate calculated from center** — `translate(calc(-50% + dx), calc(-50% + dy))` so the shard's visual center lands at the target offset.
  5. **Stagger more densely** (0.15s between shards, not 0.3s) and use shorter lifetime (~1.8s vs 2s) so there are always shards in flight; the motion reads as "ongoing burst" instead of "sequential drops."
  6. **Scale in from 0.5 → 1** during the first 15% of the lifetime so each shard *appears* at the button and then flies outward — classic firework/confetti cannon feel.
- **Count**: 1
- **Status**: active

### FIX-039 — Implemented a visual mockup state as a prop-gated feature with nothing to turn it on
- **Date**: 2026-04-23
- **Mode**: implement (ChatWidget celebration state from v3.html S8)
- **What happened**: User asked to implement S8 Celebrating from v3.html into the real ChatWidget. I added a `celebrating?: boolean` prop that defaults to `false`, wired the gradient+confetti behind it, and declared done. Nothing in the consumer (`DaxbotWidget`) sets it true, so the real button rendered exactly as before. User followed up with "no change" + screenshot showing the idle green bot. Still not aligned: my celebrating state kept the `RobotIcon` (bot head), but the mockup uses the sparkle glyph — so even when the prop would have been true, the glyph wouldn't match. Also missed that `@daxwell/ui` resolves to `./dist/*` so source edits need a package rebuild to be picked up.
- **User correction**: "still not looks as [mockup image], i want same"
- **Root cause**: `incomplete-phase` — "implementing a mockup state" requires three things, not one: (a) the code path exists, (b) a trigger actually renders it in the app so the user can see it, (c) the package that owns the code is rebuilt so the runtime sees the new code. I did (a) only. Also missed a **style-drift** sub-issue — the icon glyph was not pixel-matched to the mockup (LR-002).
- **Correct behavior**: When implementing a discrete visual state from a mockup (celebration, error, loading, etc.):
  1. **Pick one default wiring** — either make the state observable by a known trigger (first-chat, completion, explicit prop=true demo), or gate it behind the prop AND flip the prop in the consumer for the first ship. Don't leave a prop dangling with no way to see the result.
  2. **Diff the glyph, not just the chrome** — the mockup's icon/shape is part of the state. If the mockup swaps the bot head for a sparkle (as S8 does), the implementation must too. Pixel-match per LR-002 applies to icon geometry, not just color/spacing.
  3. **Trace package resolution before declaring done** — if the consuming app reaches into `@daxwell/ui` via `./dist/*` exports, a source-only edit is invisible at runtime. Either (a) run `pnpm --filter @daxwell/ui build` after the edit, or (b) confirm `pnpm --filter @daxwell/ui dev` is running in watch mode, or (c) tell the user in the final summary that a rebuild is required. Silent dist/src divergence is a completeness bug.
  4. **Verify with the user's view, not with lint/types alone** — lint+types green is necessary but not sufficient for "mockup implemented" claims; the feature has to actually render in the app the user is looking at.
- **Count**: 1
- **Status**: active (flip celebrating in consumer, swap glyph to sparkle when celebrating, rebuild package)

### FIX-038 — Guessed a size (34) by eyeball after already deriving the exact measured spec (36) from the reference element
- **Date**: 2026-04-23
- **Mode**: fix (Daxbot inline icon alignment with Searchbar trigger)
- **What happened**: User asked to align the Daxbot IconButton height with the Searchbar. In the same response I correctly derived the Searchbar's computed height from its code (`p:1` + 20px Iconify glyph = 8 + 20 + 8 = **36px**), then set `width/height: 34` anyway with rationale "34×34 is a good middle ground". User immediately corrected: "it should be 36".
- **User correction**: "it should be 36"
- **Root cause**: `assumption-error` — I measured the reference spec correctly, wrote the measurement in the direction brief, then picked a different number by eyeball when writing code. The spec existed; I overrode it with a vibe.
- **Correct behavior**: When aligning one element's size with another, if the reference element's computed size is derivable from code (padding + content + padding), **use that exact number**. Do not soften it to a "nicer-looking" value. If the computed number disagrees with how the two elements actually look side-by-side, investigate the mismatch (zoom, screenshot compression, different box-sizing, border math) before picking a different value — don't just split the difference.
- **Count**: 1
- **Status**: active (34 → 36)

### FIX-037 — Solved a null-bubble by defaulting the `@include` variable to false, silently losing data for legitimate readers
- **Date**: 2026-04-22
- **Mode**: fix (`GET_CURRENT_APP_USER` + `CURRENT_APP_USER_FRAGMENT` — AppUserDefaultRole.defaultRole non-null bubble)
- **What happened**: After earlier fixes gated the inner `defaultRole { ...RoleBase }` behind `$includeDefaultRole: Boolean = false`, the profile page's server-side `GET_CURRENT_APP_USER` fetch in `user-profile-server-view.tsx` never passed the variable, so even admin users saw "Default Role: N/A" on their own profile. I optimized for the non-admin crash path and forgot the admin/readable path.
- **User correction**: "i want like if user has admin role and switches to other role then he should still see all info which are required for profile ... like you can see as i am admin still not able to see default role"
- **Root cause**: `assumption-error` — when using `@include` to gate a field behind a permission variable, I defaulted the variable to `false` and only opted in at callers that looked like "they need the data" (e.g. the edit modal). I didn't opt in the read-only surface (profile view) that also needs the data whenever the user has Role READ. Default-false means every caller that forgets to opt in silently loses the field even when the backend would have happily returned it.
- **Correct behavior**: When gating a nested field with `@include(if: $var)` to tolerate a backend non-null bubble:
  1. Audit **every consumer** of the query/fragment before committing. For each, decide: do they render the inner field? If yes, they must opt in. If no, they can stay on the default.
  2. On SSR surfaces where Redux permission state isn't available, opt in unconditionally (`includeDefaultRole: true`) as long as the parent field is nullable (so the bubble lands there for users without Role READ). Check schema nullability before setting this — in this repo, `CurrentAppUser.defaultRole: AppUserDefaultRole` is nullable, so the bubble is safe.
  3. Treat `@include` default-false as **opt-in-by-caller** for dynamic permission variables, not as a global kill switch. Document the expected caller values in a one-line comment near the query (or in the PR description), not via a default that silently hides data.
  4. Test the admin read path and the non-admin read path both before declaring the fix done — admins must see the data; non-admins must not crash.
- **Count**: 1
- **Status**: active (opt in from `user-profile-server-view.tsx`)

### FIX-036 — Stopped at named entity and flagged siblings as "out of scope" instead of finishing the systemic fix
- **Date**: 2026-04-22
- **Mode**: fix (role-associated-pages for PaymentTerm in `path-permission-map.ts` + `get-permissions-for-path.ts` + `entity-route-mapping.ts`)
- **What happened**: User asked why the Payment Terms page wasn't appearing in the role's Associated Pages for the PaymentTerm entity. During investigation I identified that the same three-file wiring was also missing for the sibling business-objects routes (`paymentMethods`, `transportationHandlingUnit`, `locations`). Instead of fixing all four in one turn, I fixed only PaymentTerm and surfaced the other three as "Flagged as sibling gaps (not fixed — out of scope for this request)" at the bottom of the response. User had to come back with "--fix above same issue for all business objects" to get the systemic fix applied.
- **User correction**: "--fix above same issue for all business objects"
- **Root cause**: `incomplete-phase` — treated "the user named X" as "fix only X". When a fix reveals that N>1 siblings share the exact same bug caused by the exact same missing wiring, the user almost always wants the pattern fixed everywhere in one turn. LR-013 already encodes the inverse intent ("when you add a nav route, update all 9 files"); the symmetric rule for bug fixes is "when you find a systemic gap affecting N siblings, close the whole set".
- **Correct behavior**: When the fix mode diagnosis identifies that the same root cause applies to N sibling items in the same file/section:
  1. Fix all N in the same turn (same three-file pattern, same style).
  2. In the summary, list all N fixed — don't split them into "fixed one / flagged others".
  3. Only defer siblings to a follow-up turn if: (a) the fix requires per-item data the user hasn't provided, OR (b) the fix is architecturally risky per-item (unknown entity type, ambiguous naming), OR (c) the user explicitly said "just this one". Document which exception was hit.
  4. For LR-013 business-objects sections specifically, treat every route in `paths.dashboard.businessObjects.*` as a checkable unit — if one is missing wiring, scan the whole subtree and fix the set in one commit's worth of edits.
- **Count**: 1
- **Status**: active; entry retained for promotion review

### FIX-035 — Ran eslint but skipped `mcp__ide__getDiagnostics` type-check across ~10 edits in one session
- **Date**: 2026-04-22
- **Mode**: fix + implement (button system theme changes, filter-nav-by-permissions, dashboard/layout.tsx, path-permission-map.ts, action-button.tsx)
- **What happened**: Across roughly 10 file edits in a single session (nav-floating reshuffles, action-button styling, theme primary palette swap, filter-nav-by-permissions fetch wiring, path-permission-map Product/PackagedProduct minimums), I ran `pnpm eslint --fix <file>` every time but **never invoked `mcp__ide__getDiagnostics` once**. The type-check half of LR-009 was silently skipped for the entire session.
- **User correction**: "still forgot to run eslint format and type-check for touched files"
- **Root cause**: `incomplete-phase` — repeat of FIX-027 pattern. Treated "lint is clean" as a proxy for "quality gate passed", which it is not. The lint pass catches zero type errors; type-check is the only signal for broken imports, type drift after a refactor, and `any` leakage. LR-009 already documents this exact failure mode from 2026-04-20, and yet I repeated it in the very next week.
- **Correct behavior**: After each Edit/Write, immediately invoke BOTH `pnpm eslint --fix` AND `mcp__ide__getDiagnostics` for every touched file — as two paired tool calls, not an either/or. The gate is AND, not OR. If I ran only one, I haven't run the gate. The pre-response self-check must explicitly verify both tools were called for each touched file in the current turn; if the answer is "only eslint", block the response and run the missing half.
- **Count**: 3 (FIX-027 + two prior implicit skips that rolled up into LR-009 promotions) — now being reinforced into LR-009 as "eslint-only shortcut is forbidden."
- **Status**: active; LR-009 updated with explicit "AND, not OR" framing + third reinforcement date.

### FIX-034 — Misread user's "no" as "revert" when it meant "next, also check…"
- **Date**: 2026-04-21
- **Mode**: fix (chat + intel API proxy routes in `apps/scm/src/app/api/`)
- **What happened**: After I removed `X-User-Email` from 9 Next.js proxy routes, user said: "no check in daxbot-api backend which is in ../ and make sure it using X-User-Email". I parsed that as "No — stop, the backend still relies on it, put it back". I started reverting the files (restored one: `chat/route.ts`) before the user interrupted: "why reverting it, just now i said i don't want to pass X-User-Email". The user's actual intent was the opposite — the `no` was a sentence-starter ("no need to worry", "nope — now do this next"), and the real instruction was to verify the daxbot-api backend to confirm the consumer side is (or will be) updated. The desired end-state is **only `Authorization` forwarded**, no `X-User-Email` — same as the daxbot-readstream handler direction. daxbot-api needs to switch from `X-User-Email` to extracting the user from the JWT in `Authorization`. That's a daxbot-api-side change the user is aware of and owns.
- **User correction**: "why reverting it, just now i said i don't want to pass X-User-Email, i just want to pass Authorization token"
- **Root cause**: `assumption-error` — treated a short ambiguous utterance as a directive without confirming. "no" at the start of a user message is frequently a discourse marker, not a command to undo. Should have clarified ("do you want me to put it back, or proceed with the removal and let the backend catch up?") before any file-level action.
- **Correct behavior**: When a user message starts with a bare "no" and the rest of the sentence is not an explicit reversal, do not assume it means "revert". Either ask a one-line clarifying question, or at minimum list the two possible interpretations in the reply before acting. Only act destructively (reverting committed intent) when the user's text explicitly says to revert / undo / restore.
- **Count**: 1
- **Status**: active; re-reverted `chat/route.ts` so all 9 files are back in the no-`X-User-Email` state. daxbot-api side is the user's responsibility.

### FIX-033 — Guessed toolbar padding instead of using explicit height target
- **Date**: 2026-04-21
- **Mode**: fix (list toolbar vertical sizing in `packages/ui/src/components/list-page-view/list-table-view.tsx`)
- **What happened**: User asked to match mockup toolbar height. I reduced `py: '12px'` → `py: '10px'` based on the mockup CSS (`padding: 10px 32px`), treating the mockup's CSS value as the source of truth. User corrected with an explicit target: `height should be 45`. The previous `py: 10px` + intrinsic child content height (30px button tallest) produced ~50px, still too tall.
- **User correction**: "height should be 45"
- **Root cause**: `assumption-error` — I assumed mockup-derived padding was the right dimension to match, rather than asking/targeting an explicit total height. For fixed-height visual containers, the right primitive is `minHeight`/`height` on the container, not padding math through content sizes.
- **Correct behavior**: When user says "toolbar height should be X", set `minHeight: X` (or fixed `height: X` if the toolbar must never grow) on the container directly and set `py: 0` so children's flex alignment handles vertical centering. Don't infer padding from the mockup CSS — mockup padding assumes a specific inner content height; if our MUI children render at different intrinsic heights, the container total won't match.
- **Count**: 1
- **Status**: active

### FIX-032 — `GET_MINIMAL_CURRENT_APP_USER` over-selected a non-nullable nested field that the backend returns null for after role switch
- **Date**: 2026-04-21
- **Mode**: fix (navigation to /developer-console after switching role)
- **What happened**: Navigating to `/developer-console` after switching the active role threw a GraphQL error: `The field at path '/getMinimalCurrentAppUser/defaultRole/defaultRole' was declared as a non-nullable field, but the code involved in retrieving data has wrongly returned a null value.` The query's inner `defaultRole { ...RoleBase }` subselection (inside `AppUserDefaultRole`) is typed `Role!` on the server, but for some user/role combinations after a role switch the backend resolver returns null for that inner pointer — violating the non-null contract. `errorPolicy: 'all'` still propagates the null up to the parent and surfaces the error in the dev overlay.
- **User correction**: Screenshot of the Apollo error with `classification: "NullValueInNonNullableField"` + context "when I switch role and navigate to developer console page".
- **Root cause**: `framework-leak` — the query selected a schema-non-null field that the backend data layer can still nullify (schema / data drift after role switching). The frontend has no way to tolerate null on a field typed non-null — the only safe fix is to stop selecting it.
- **Correct behavior**: Remove the inner `defaultRole { ...RoleBase }` subselection from `GET_MINIMAL_CURRENT_APP_USER`. Keep the outer `AppUserDefaultRole { id, app }` because `profile-guard.tsx` still dereferences `appUser.defaultRole` for null-check logic. The lost field (inner role name) was only used by the NO_PERMISSION auto-resolution path in profile-guard — reduces that narrow feature to a no-op on the minimal query (acceptable because profile-guard also runs on the full query for profile-scoped pages). Alternatively, ask the backend to mark the inner field nullable — but the frontend fix is immediate and eliminates the error class entirely.
- **Count**: 1
- **Status**: active; flag to backend as a schema-vs-data inconsistency worth fixing properly

### FIX-031 — Boolean SSRM filter requires `type: 'true'|'false'` (no `filter` field); `type: 'equals' + filter: 'true'` is silently ignored
- **Date**: 2026-04-21
- **Mode**: fix (developers-list-view count probes + filter toggle)
- **What happened**: After FIX-029 (switching `filterType` from 'text' to 'boolean'), my probes and toggle handler were sending `{colId:'isDeveloper', filterType:'boolean', type:'equals', filter:'true'}`. Query executed but returned `totalRows: 57` — the UNFILTERED total. I mis-diagnosed this in FIX-030 as "backend ignores filter in count path" and worked around it with a 10000-row tally. User provided the proven-working shape: `{colId:'isDeveloper', filterType:'boolean', type:'true'}` — NO `filter` field, `type` itself carries the boolean value. With that shape, `totalRows` correctly returns the filtered count.
- **User correction**: Supplied the exact GraphQL shape that worked on their backend with `type: "true"` and no `filter` property.
- **Root cause**: `assumption-error` — I assumed `type: 'equals'` was universal across filter types (true for text/number filters). For a boolean filter the wire contract differs: the `type` field carries the truthiness directly (`'true'` or `'false'`), and there is NO `filter` field. FIX-030's "backend count is broken" conclusion was wrong — the count path was fine all along; the filter shape was wrong and the backend ignored the malformed predicate rather than erroring.
- **Correct behavior**:
  1. Boolean SSRM filter shape: `{colId, filterType:'boolean', type:'true'|'false'}` — omit the `filter` field entirely.
  2. Text filter shape still uses `{filterType:'text', type:'equals'|'contains'|..., filter:'value'}`.
  3. When a filtered probe returns the unfiltered total, FIRST suspect the filter shape (backend silently ignores unknown filter fields) rather than assuming the backend is broken.
  4. Apply the same shape symmetrically: count probes AND the grid's own filter model (via `api.setFilterModel`) must both use the boolean shape — otherwise the toggle would trigger the same silent bypass.
- **Count**: 1
- **Status**: active; supersedes FIX-030's incorrect diagnosis

### FIX-030 — Separate count `useQuery` returned unfiltered total; backend didn't honor the filter in count path
- **Date**: 2026-04-21
- **Mode**: fix (developers-list-view stat card)
- **What happened**: Used two parallel `useQuery(GET_DEV_ADMIN_APP_USER_ROWS)` probes to populate stat cards — one unfiltered for total, one with `filterModels: [{colId:'isDeveloper', filterType:'boolean',...}]` for the developer count. The filtered probe returned `totalRows: 57` (the unfiltered total of 57 users) instead of the actual 2 developers. The filter worked correctly for the main SSRM row list but was silently ignored in the count-probe path.
- **User correction**: "developers are actually 2 but i can see 57. so i think we need to use sortModal" — prompted me to abandon the side-channel count and derive counts from the active SSRM datasource instead.
- **Root cause**: `assumption-error` — assumed firing the same query with `startRow:0, endRow:1` would yield a filtered totalRows. In practice, the backend's count path doesn't guarantee the same filter parsing as the list path; my count probe silently fell back to unfiltered. Also violates LR-026 (prefer dedicated count queries) — since no dedicated count query exists, a list-query-with-endRow=1 probe is a brittle workaround.
- **Correct behavior**: Derive stat counts from the single SSRM datasource via its `onTotalRows` callback. Maintain a small memo of `{total, developer, standard}` counts keyed by the active filter tab — each filter click repopulates the correct slot. If two of the three are known, the third is `total - known`. Single source of truth, zero extra queries, accuracy guaranteed because the filter that drove the rows is the filter that drove the count. Remove the parallel `useQuery` count probes.
- **Count**: 1
- **Status**: active

### FIX-029 — Boolean column sent with `filterType: 'text'`; backend wraps in `lower()` and Postgres rejects
- **Date**: 2026-04-21
- **Mode**: implement (developers-list-view filter model shape)
- **What happened**: Built the Developers page with two paths that filter the boolean `isDeveloper` column. Count query sent `{colId:'isDeveloper', filterType:'text', type:'equals', filter:'true'}`. Toggle handler sent `{filterType:'set', values:['true'|'false']}` which `ServerSideDatasource.mapFilters` auto-converts to the same text-equals shape. Backend's text path wraps the column in `lower(col)` for case-insensitive compare → Postgres raises `function lower(boolean) does not exist`. Query fails entirely; the apollo error link surfaced as `[Apollo error] {}` (the separate noise-gate fix from this session).
- **User correction**: "filterType should be boolean" + the actual Postgres error showing `lower(boolean) does not exist`.
- **Root cause**: `framework-leak` — assumed SSRM text-equals is a universal filter shape, but the backend branches on `filterType` to decide SQL coercion. Boolean columns must send `filterType: 'boolean'` so the backend compares natively instead of coercing via `lower()`.
- **Correct behavior**:
  1. When filtering a boolean column via SSRM, the filter model value must be `{filterType:'boolean', type:'equals', filter:'true'|'false'}` — NOT the set-filter shape and NOT `filterType:'text'`.
  2. ListTableView's `tabToFilterMapping` produces a set-filter shape → not usable for boolean columns. Use `gridApiRef.current.setFilterModel(...)` with the explicit boolean shape instead of the tabs prop.
  3. Applies symmetrically to `useQuery` count probes that carry `filterModels: [...]` — use the same `filterType:'boolean'` for boolean predicates there.
  4. For any new SSRM filter on a non-text column type (boolean, number, date), verify the backend's SQL coercion by checking server logs on first fetch, not just the compile type. The frontend `filterType` string is a contract with the backend resolver.
- **Count**: 1
- **Status**: active

### FIX-028 — Check-mode findings emitted inline to chat instead of persisted under docs/checks
- **Date**: 2026-04-20
- **Mode**: check (auto-logout logic review)
- **What happened**: User ran `--check auto-logout feature logic`. I produced a full risk-rated finding set (2 HIGH · 4 MEDIUM · 3 LOW) inline in the chat. The user then had to manually ask me to "write those check in docs/checks folder and also ignore it" — meaning the findings needed to be persisted somewhere they could be picked up later for follow-up fixes, not lost in the chat transcript.
- **User correction**: "write those check in docs/checks folder and also ignore it" + "that when ever we check mode then write in docs/checks and once implemented then remove it from docs/checks" (as a learn rule).
- **Root cause**: `incomplete-phase` — check mode's deliverable isn't just a chat answer. Findings have a lifecycle (open → triaged → fixed → removed), and that lifecycle needs a filesystem backing so multiple sessions / commits can reference them. Inline-only output creates a "check was run, findings vanished" anti-pattern.
- **Correct behavior**: Every `--check` run writes its findings to `docs/checks/<feature-slug>-logic-check.md` using the same format the chat would use (findings table + summary + verdict + non-findings notes). The chat output can still summarize, but the persisted file is the source of truth. When those findings are later implemented (via `--fix` or `--implement`), the corresponding file is deleted from `docs/checks/` to keep the folder representing only the open-finding backlog. If only some findings from a file are implemented, the file is updated with the remaining ones rather than fully deleted.
- **Count**: 1
- **Status**: [PROMOTED] → LR-029

### FIX-027 — Skipped mandatory eslint-fix + type-check gate across multiple edits
- **Date**: 2026-04-20
- **Mode**: fix, implement (location CRUD + filter chips + hook-level audit-column change + search-field polish — repeated across several turns)
- **What happened**: Throughout a run of ~10 edits to the Location list view, shared `use-table-columns.tsx` hook, `crud-list-page/index.tsx`, and `list-table-view.tsx`, I did not invoke `pnpm --filter scm lint --fix` nor call `mcp__ide__getDiagnostics` proactively. I relied on the ambient diagnostic-auto-reporter to surface issues (e.g. the LuHome build error, the useMemo dependency warning, the prettier comma/formatting warning) instead of running the checks myself. This is a direct violation of LR-009 — the rule I'm meant to treat as non-negotiable after every edit, even trivial one-liners.
- **User correction**: "again eslint and type-check is not performed".
- **Root cause**: `incomplete-phase` — trusting reactive diagnostics instead of proactively invoking the gate. LR-009 already forbids this. The recurrence means the rule needs tightening (explicit "both tools must be invoked, even for single-line edits; passive diagnostics do not substitute for active verification") and it needs to be the first item in the pre-response self-check gate.
- **Correct behavior**: For every file edit — including one-character renames and label-string swaps — the final action before responding must be (1) `pnpm --filter <app> lint --fix <touched-paths>` (or the equivalent eslint invocation) AND (2) `mcp__ide__getDiagnostics` per touched file URI. Passive diagnostic notifications count as coverage only when they fire on the exact file just edited; they do not replace running the lint fixer. Never declare done without evidence of both.
- **Count**: 3+ (user has flagged this in multiple sessions; see LR-009 promotion history)
- **Status**: active — reinforces LR-009; no new promotion needed

### FIX-026 — Audit-column "always at end" fix only covered the visibleFieldsOrdered path
- **Date**: 2026-04-20
- **Mode**: fix (use-table-columns hook)
- **What happened**: User reported that audit columns (Created By/Date, Last Modified By/Date) should always appear at the end of every list-view grid. My first attempt partitioned `orderedCols` (built from `visibleFieldsOrdered`) into non-audit + audit. But when a consumer omits audit fields from `visibleFieldsOrdered` (which is the common case — most list views have `onlyFieldsWithOrdered: false`), audit columns flow through the `remainingCols` branch built from `fieldMap.keys()` — and `fieldMap` order reflects backend GraphQL class metadata, which puts audit fields wherever the schema declares them. Result: columns rendered as `... Last Modified Date, Last Modified By, Created Date, Created By, Weight Uom, Volume Uom, Actions` — audit fields mid-tail, wrong order (newest-first), followed by unrelated trailing columns.
- **User correction**: "still not at end" with screenshot showing audit columns mixed into the tail instead of at the very end.
- **Root cause**: `incomplete-phase` — I only patched one of the two code paths that emit columns. The fix needed to cover both the ordered and the auto-added branches, AND normalize audit column ordering to a fixed canonical sequence (createdBy → createdDate → lastModifiedBy → lastModifiedDate) rather than whatever order they appear in the source arrays.
- **Correct behavior**: After building both `orderedCols` and `remainingCols`, strip audit fields from both, then append a canonical-ordered audit column block at the very end of the final `all` array. Works regardless of whether audit fields appeared in `visibleFieldsOrdered`, in field metadata, or both.
- **Count**: 1
- **Status**: active

### FIX-025 — Cross-section hook import instead of promoting to a shared location
- **Date**: 2026-04-20
- **Mode**: fix (transportation-handling-unit-list-view wiring `useSectionMeta`)
- **What happened**: To wire `sectionMeta` + per-field validity into the THU modal, I imported `useSectionMeta` from `@/sections/xwalk/shared` — a section-specific folder owned by a different feature (xwalk). The hook is reused by multiple section views (service-policy-assignment, now THU), so pulling it across sections creates hidden coupling: the THU section now depends on xwalk's internal structure, and any xwalk refactor breaks THU.
- **User correction**: "if need to reuse then always create a sharable component at global level and use wherever required but don't do like +import { useSectionMeta } from '@/sections/xwalk/shared'".
- **Root cause**: `style-drift` — matched the service-policy-assignment import path verbatim without questioning whether a section-local path was appropriate for a cross-section reuse. LR-023 covers this for UI components but I didn't apply the same logic to hooks/utilities.
- **Correct behavior**: Any hook, utility, or component used by 2+ sections must live in a global shared location (`packages/ui/src/hooks/`, `packages/utils/src/`, or `packages/shared/` as appropriate), imported via the `@daxwell/*` alias — not `@/sections/*`. When encountering an existing section-local import that meets this criteria, promote it before importing.
- **Count**: 1
- **Status**: [PROMOTED] → LR-028

### FIX-024 — Upload file list accepted duplicate files, triggering React duplicate-key warning
- **Date**: 2026-04-20
- **Mode**: fix (file-manager upload dialog)
- **What happened**: After fixing the "modal closes on drop" issue, files were appended without deduplication in three places — wrapper's `handleDrop`, dialog's `handleDrop`, and the `initialFiles` sync `useEffect`. Dropping the same file twice produced two entries in the list. The `MultiFilePreview` component keys by file name, so React logged `Encountered two children with the same key, Hello World! (1).txt`.
- **User correction**: "when i drag and drop files one by one then it is override the already dragged files… handle list no duplicate".
- **Root cause**: `skipped-state` — didn't consider the duplicate-drop state when designing the append flow. Append is correct for new files but must be idempotent per file identity (name + size + lastModified for File, string equality for URL).
- **Correct behavior**: All three add points dedupe incoming files against the existing list using a shared `mergeUniqueFiles` helper. File identity = name + size + lastModified. String identity = raw string.
- **Count**: 1
- **Status**: active

### FIX-023 — Added nav entry without scaffolding the matching page + section view; clicking the link would 404
- **Date**: 2026-04-20
- **Mode**: fix (nav-config-floating)
- **What happened**: User asked to add `transfortationHandlingUnit` to the floating nav. I added the nav item and stopped there, flagging the remaining files per LR-013 as follow-ups. But LR-013 is about full production routing (permissions, entity mapping) — the user's expectation for a nav-add is that the link at minimum resolves to a rendering page, not a 404. The path existed in `paths.ts`, nav item pointed at it, but no `app/dashboard/business-objects/transfortation-handling-unit/page.tsx` existed, and no section view existed. Clicking the new nav entry would 404.
- **User correction**: "when i ask to add any nav then related to that also create template file of this… create a folder with transportation-handling-unit this type pattern and inside that create a page.tsx and simple [template]… and then in sections folder under same name create folders as view and add a sample text to display on screen."
- **Root cause**: `incomplete-phase` — treated the nav-add as a single-file edit when the user's mental model is "nav entry = working link". The minimum viable scaffold (page.tsx + section stub) is part of the task, not a follow-up.
- **Correct behavior**: Any nav-add creates the Next.js page file (using the accounting-item-categories template) and a minimal section view stub in the matching section folder. LR-013's broader checklist still applies for fully-finished features; this rule covers the minimum to avoid dead links. Promoted immediately as LR-027.
- **Count**: 1
- **Status**: [PROMOTED] → LR-027

### FIX-022 — `flattenTop` on the outer GridWrapper gated on `!isServerMode`, leaving the grid top corners rounded in server mode
- **Date**: 2026-04-18
- **Mode**: fix (CrudListPage — outer GridWrapper flattenTop)
- **What happened**: In `packages/ui/src/components/crud-list-page/index.tsx`, the outer `GridWrapper` was passed `flattenTop={showToolbar && !isServerMode}`. In server mode this evaluated to `false`, so the outer wrapper applied `borderRadius: 14px` to every descendant `.ag-root-wrapper`. The inner `ListTableView`'s own `GridWrapper` tried to set `flattenTop=true` ('0 0 14px 14px'), but the outer rule competed via equal specificity — the visible grid kept rounded top-left/top-right corners even though the toolbar above was meant to visually merge.
- **User correction**: "still i can see that when we have toolbar but still on top left and right corner of table has border radius but it should be 0 border radius".
- **Root cause**: `assumption-error` — I wrongly assumed that in server mode the outer wrapper did not need `flattenTop` because `ListTableView` has its own `GridWrapper`. In fact the outer wrapper's `.ag-root-wrapper` sx still cascades to the inner AG Grid instance, so both wrappers must agree when a toolbar is shown above the grid.
- **Correct behavior**: When two `GridWrapper`s are nested (outer + one inside `ListTableView`), both must be given the same `flattenTop` value as the inner one whenever a toolbar is visible. The simplest rule: `flattenTop={showToolbar}` — it holds in both client and server modes because the default toolbar (search + export + refresh + left label) is always rendered unless explicitly hidden.
- **Count**: 1
- **Status**: active

### FIX-021 — Gated a toolbar button on an optional prop, hiding it by default; mixed button/input heights
- **Date**: 2026-04-18
- **Mode**: fix (CrudListPage toolbar — Export/Refresh)
- **What happened**: Added an Export + Refresh pair to the client-mode toolbar but rendered the Refresh button only when the consumer passed `onRefresh`. No existing caller does, so the button never appeared — user screenshot showed only the download icon. Separately, I built the search TextField at `height: 36` but the buttons at `32×32` — sizes clearly mismatched next to each other.
- **User correction**: "i can't see refresh button and also i want you to make sure to have the same width and size of the buttons and searchbar".
- **Root cause**: `skipped-state` (refresh) + `style-drift` (size mismatch). The refresh-button gating was over-cautious: when replicating a toolbar that's visually a fixed trio (search + export + refresh), hiding one element by default breaks the visual spec even if it avoids a dead handler. For size: I pulled dimensions from two separate references (search from my own TextField sx, buttons from ListTableView's 32×32 style) without reconciling.
- **Correct behavior**:
  1. When replicating a fixed visual pattern (here: search + export + refresh triad from ListTableView), all elements must render consistently. Feature-gate behavior inside the handler, not visibility of the control.
  2. Always provide a sensible fallback for optional callback props — for a refresh button in client mode without an `onRefresh`, call AG Grid's `api.redrawRows()` so the click isn't a no-op.
  3. When placing inputs and icon-buttons on the same row, pin both to the same height (typically 36px or 40px) so their vertical edges align. Pull the dimension from one source and reuse, not two separate specs.
- **Count**: 1
- **Status**: active

### FIX-020 — Client-mode CrudListPage rendered a floating search input, diverging from server-mode's toolbar card
- **Date**: 2026-04-18
- **Mode**: fix (CrudListPage client-mode layout)
- **What happened**: After the earlier pagination cleanup (FIX-017) I left client mode with a bare `<TextField>` sitting in its own row above the grid. Server mode renders a proper toolbar card (dark bg, rounded top corners, search on the right, flat top on grid) because it delegates to `<ListTableView>`. Client mode had no toolbar — just a naked search input in a `<Stack>` with no card chrome — so the same page type looked visually different depending on whether `mode='server'` or `mode='client'` was passed.
- **User correction**: "in when client mode it should also i want to look like list table view" + screenshots showing the bare search input (Image #13, #15) vs ListTableView's toolbar card (Image #14).
- **Root cause**: `skipped-zone` — when I deleted the custom pagination bar in FIX-017, I left the search in its own row instead of rebuilding the toolbar treatment. Client mode inherited the "no toolbar" shape accidentally.
- **Correct behavior**:
  1. When a shared component supports both client and server modes, both modes must share the same visual chrome (toolbar, grid treatment, empty states). Divergence is a regression even if each mode works in isolation.
  2. After removing a feature (like the custom pagination bar), re-check the remaining layout to ensure the other chrome elements still compose correctly. Don't just delete the removed code and move on.
  3. `<ListTableView>` is server-mode only. For client-mode grids that need the same look, rebuild the toolbar card inline rather than trying to force ListTableView into client mode.
- **Count**: 1
- **Status**: active

### META-019 — Silently skipping the "eslint --fix on touched files" exit-checklist item
- **Date**: 2026-04-18
- **Mode**: all (meta / workflow)
- **What happened**: Across multiple fixes this session (CrudListPage pagination removal, TypingIndicator label state machine, GridWrapper flattenTop, chat-widget label switching) I completed the code changes and reported "done" without running `eslint --fix` on the touched files. The skill's fix-mode and implement-mode exit checklists both require it. I was skipping because each invocation triggers a harness permission prompt (commands aren't on the `.claude/settings.json` allowlist), and one earlier prompt this session was rejected — so I started assuming quietly that the user didn't want me to run lint. That's a wrong inference; the rejection was likely scope-specific ("don't run the entire workspace lint right now"), not a blanket opt-out.
- **User correction**: "biz-ui-forge is not running eslint format on touched files".
- **Root cause**: `incomplete-phase` — treating exit-checklist items as optional when they trigger friction. A permission prompt is a gate to negotiate with the user, not a signal to abandon the step.
- **Correct behavior**:
  1. Always attempt the exit-checklist commands. If the harness prompts, let the user approve or decline **for that specific scope**.
  2. If a command is repeatedly needed (every fix), proactively offer to add it to `.claude/settings.json` permissions allowlist so future prompts don't fire. Do this after the *first* repeated friction, not after the user calls it out.
  3. If I choose to skip the step for a stated reason (e.g., "skipping lint because the previous prompt was rejected"), flag it explicitly in the response so the user sees the omission — don't silently drop it.
  4. Narrow the lint invocation to the touched files (`pnpm exec eslint --fix <paths>`) rather than the whole workspace (`pnpm --filter scm lint`) when only a handful of files changed — faster and easier to approve.
- **Count**: 1
- **Status**: active

### FIX-018 — Grid top border-radius flickers when consumer-sx tries to override GridWrapper's internal sx
- **Date**: 2026-04-18
- **Mode**: fix (ListTableView top-corner radius when toolbar is present)
- **What happened**: `GridWrapper`'s internal sx sets `'& .ag-root-wrapper': { borderRadius: '14px' }` unconditionally. `ListTableView` tried to flatten the top corners when a toolbar is rendered by passing `sx={{ '& .ag-root-wrapper': { borderRadius: '0 0 14px 14px' } }}`. Because both rules live in the same Box's sx array and target the **exact same nested selector**, they emit as two separate emotion classes. Which class wins depends on the order emotion inserts them into the stylesheet — and that order is non-deterministic across remounts/HMR (emotion's speedy cache re-uses existing classes and only inserts new ones at the end). Result: sometimes the consumer override wins and the top corners flatten correctly; sometimes the internal 14px rule wins and the corners stay rounded behind the toolbar.
- **User correction**: "sometimes when we have toolbar in list table view component then still border radius of table is shown but i want then toolbar is present then table top right and left should be no border radius. It is not stable" + screenshot of rounded top corners below a toolbar.
- **Root cause**: `style-drift` — competing-specificity override between a shared component's baseline sx and a consumer's patch sx for the same selector. Also a layout concern: the shared primitive (`GridWrapper`) doesn't know about toolbar presence, so the override has to come from outside, but the two styles collide on the same selector with equal specificity.
- **Correct behavior**:
  1. When a shared primitive needs visually-variant states (rounded vs square top, padded vs flush), expose the variant as a **prop** on the primitive. Don't let consumers win a CSS-specificity race against the primitive's own internal sx.
  2. If you must override a primitive's nested selector from the consumer side, bump specificity with `&&` (doubles the class) or `!important`, and write a comment explaining why — but this is a last resort; lifting the state into a prop is preferable.
  3. When adding a new prop to `GridWrapper` (or any shared layout primitive), default it to the current behavior so existing callers don't regress.
- **Count**: 1
- **Status**: active

### FIX-017 — Overrode AG Grid's native pagination with a custom `<GridPagination>` bar
- **Date**: 2026-04-18
- **Mode**: fix (CrudListPage pagination)
- **What happened**: `packages/ui/src/components/crud-list-page/index.tsx` rendered a custom `<GridPagination>` bar ("Rows per page 20 ▾ 1 to 8 of 8") above the grid, and passed `hideNativePagination` to `<GridWrapper>` to suppress AG Grid's built-in pagination. To feed the custom bar, the file duplicated state: `currentPage`, `activePageSize`, `serverPagination`, a paginationChanged event listener, plus `paginatedData = filteredData.slice(...)` instead of letting AG Grid slice internally. User wanted the native AG Grid pagination back and the custom override removed.
- **User correction**: "in this no need to override ag grid react, remove this" + screenshot of the custom rows-per-page bar.
- **Root cause**: `framework-leak` — reinvented a feature that AG Grid already provides (`pagination={true}`, `paginationPageSize`, `paginationPageSizeSelector` for client mode; SSRM pagination for server mode). The wrapper added ~100 lines of state/handlers, an extra render path, and a divergence risk (custom bar could show wrong page count if grid paged via keyboard/scroll).
- **Correct behavior**:
  1. When AG Grid ships a feature (pagination, filtering, sorting, column menu, export), consume it directly — do not wrap or mirror it in external state unless there's a concrete product reason the native UI can't satisfy.
  2. Before adding an `onGridReady`-driven state mirror (e.g. a `paginationChanged` listener that pipes grid state back into React), confirm the native UI is inadequate. 9/10 times it isn't.
  3. `hideNativePagination` on `GridWrapper` is a signal that whatever replaced it must be clearly better than AG Grid's default. If that can't be justified in one sentence, drop the override.
  4. Client mode: pass raw `rowData` to `<AgGridReact>` and set `pagination` / `paginationPageSize` / `paginationPageSizeSelector`. Don't pre-slice.
  5. Server mode: let the existing `ListTableView` / SSRM path handle pagination; don't wrap it with another event listener.
- **Count**: 1
- **Status**: active

### SUG-016 — Used a GitHub-dynamic workflow badge URL on a private repo
- **Date**: 2026-04-18
- **Mode**: fix (README badges)
- **What happened**: Added a CI badge to the README using `https://github.com/DaxwellDev/daxwell-scm-client/actions/workflows/security-audit.yml/badge.svg?branch=dev`. The repo is private (`gh repo view` → `"visibility":"PRIVATE"`), so the badge endpoint returns 404 for unauthenticated viewers and renders as a broken-image icon. User reported "ci is missing" with a screenshot of the broken-image icon next to the TypeScript and license badges.
- **User correction**: "ci is missing" + screenshot showing broken image where CI badge should be.
- **Root cause**: `assumption-error` — assumed GitHub's workflow badge URL is universally embeddable. It is only embeddable on **public** repos; on private repos the SVG endpoint requires an authenticated session, which an `<img>` tag cannot provide.
- **Correct behavior**:
  1. Before adding any badge that pulls live status from a GitHub endpoint (`actions/workflows/*.svg`, `commits/*/status.svg`, etc.), check the repo visibility (`gh repo view --json visibility`).
  2. If the repo is private, use a static `img.shields.io/badge/...` badge instead — it renders without repo access and still carries a logo and color.
  3. Document the tradeoff inline (static badges don't reflect live CI state) so future maintainers know to swap back if the repo goes public.
- **Count**: 1
- **Status**: active

### SUG-015 — Recommended a CI tool that requires a paid GitHub feature without checking repo eligibility
- **Date**: 2026-04-18
- **Mode**: suggest / implement (security tooling rollout)
- **What happened**: User asked `--suggest` for security detection in the project. I recommended enabling CodeQL (Path A of three suggestions), and when they said "implement it" I added `.github/workflows/codeql.yml`. The workflow ran successfully — CodeQL analyzed 3,572 TS files — but the SARIF upload step failed with `Code Security must be enabled for this repository to use code scanning`. The failing check blocked the PR status. User screenshot showed one red `CodeQL / Analyze (javascript-typescript) (pull_request) Failing after 5m` check, then said "i don't want this remove it".
- **User correction**: "i doon't want this remove it" + screenshot of failing CodeQL PR check.
- **Root cause**: `assumption-error` — assumed CodeQL's "default setup" toggle (which is free on public repos) was equivalent for this private org repo. In reality, CodeQL uploads to the Security tab require **GitHub Advanced Security (GHAS)**, which is a paid add-on for private-org repos. I should have verified GHAS was licensed before proposing the workflow, or at minimum flagged the license requirement as a precondition in the suggestion (not as an after-the-fact footnote).
- **Correct behavior**:
  1. Before recommending any GitHub-native security feature (CodeQL, secret scanning custom patterns, push protection for partners, Copilot Autofix), ask or verify whether the repo's org has GHAS licensed. For public repos it's free; for private-org repos it's paid.
  2. In `--suggest` output, tag each suggestion with its cost/prerequisite explicitly (e.g., "requires GHAS license" or "free on public repos only") in the **Why** or **How** line — not as a postscript.
  3. When rolling out CI security tooling on a private repo without known GHAS status, default to vendor-agnostic alternatives first: `osv-scanner` (no upload, logs only), Semgrep OSS (uploads to SaaS dashboard, free tier), or Trivy (logs only). Only propose CodeQL once GHAS is confirmed.
  4. After adding a workflow that publishes to the Security tab, run it on a throwaway branch and verify the upload step succeeds before suggesting it as a solved recommendation.
- **Count**: 1
- **Status**: active

### FIX-014 — Inline "Thinking…" shimmer appended to streaming content duplicates the bottom TypingIndicator
- **Date**: 2026-04-17
- **Mode**: fix (intel chat mid-stream waiting UI)
- **What happened**: `FormattedContent` in `chat-message.tsx` appended an inline italic "Thinking..." span to the last text line whenever `isWaiting` was true (via `THINKING_HTML`). The parent (`intel-follow-up-input.tsx`) also renders a `<TypingIndicator>` at the bottom gated on the same waiting state. Result: user sees `"…for these sales orders: *Thinking...*"` in the bot bubble AND a "Thinking..." pill below it at the same time. We had already removed the chat-thinking-indicator child, but the inline append in FormattedContent was left in place.
- **User correction**: "you can see Thinking after content, remove that i don't want that" + screenshot showing both inline italic Thinking and bottom bubble.
- **Root cause**: `incomplete-phase` — when we consolidated thinking UI into the bottom TypingIndicator, we removed the child indicator component but missed the inline shimmer path inside `FormattedContent` (different file from the one we refactored). Two rendering sites for the same state, only one was cleaned up.
- **Correct behavior**:
  1. The bottom `<TypingIndicator>` is the single source of truth for "waiting for tokens" UI.
  2. `FormattedContent` should render only the actual message content — no inline shimmer appended to the last line.
  3. When consolidating a UI state into one component, grep for every site that consumes the state flag (`isWaiting`, `isThinking`, etc.) before declaring done — not just the obvious child component.
- **Count**: 1
- **Status**: active

### FIX-013 — `replace_all` on an `<ChatInput>` JSX block missed a duplicate instance because leading indentation differed
- **Date**: 2026-04-17
- **Mode**: fix (intel stop button wiring)
- **What happened**: Added `onStop={onStop}` to the intel follow-up input by running `Edit` with `replace_all: true` on a `<ChatInput ...>` block. The file had two `<ChatInput>` instances (empty-state and populated-state). They were structurally identical token-for-token EXCEPT for leading whitespace — the empty-state one was nested 10 spaces deep, the populated-state one 6 spaces deep. `replace_all` treats the search string as exact byte match, so only the empty-state instance was updated. The populated-state instance (the one the user actually sees while streaming) silently kept the old code without `onStop`, so no stop button rendered during the active stream. User reported "still not able to see this stop" with a screenshot of the chat page's stop button.
- **User correction**: "still not able to see this stop in intel chat page" + screenshot of chat page's red stop button.
- **Root cause**: `incomplete-phase` — assumed `replace_all` would catch all JSX duplicates without verifying. JSX blocks that look textually identical may still differ in indentation because they live at different nesting depths. String-match replace tools don't normalize whitespace.
- **Correct behavior**:
  1. When `replace_all` targets a JSX block that exists in more than one location in the same file, confirm with `grep -c '<SameTag'` (or a structural search) that every instance was updated after the replace.
  2. Prefer an explicit Edit per location when the two sites live at different nesting depths — the leading indent differs and replace_all will quietly miss one.
  3. After wiring a new prop through a component, spot-check every usage of that component inside the consumer file before declaring done.
- **Count**: 1
- **Status**: active

### FIX-012 — "Try again" on 500 reloads the error page itself because the redirect didn't preserve the original path
- **Date**: 2026-04-17
- **Mode**: implement + fix (500 view retry action)
- **What happened**: Implemented `handleRetry = () => window.location.reload()` on the 500 page. From the user's perspective clicking the button "does nothing" — it actually reloads, but the current URL is `/error/500`, so the page just re-renders the same error. The same `?from=<path>` pattern already exists for 403 (FIX-011's sibling) and should have been applied here too. This is the exact same root class as the 403 UX gap — the redirect caller stripped the original URL, so the error page has no idea where the user was trying to go.
- **User correction**: "try again what does? currently when i click nothing happens" + screenshot.
- **Root cause**: `incomplete-phase` — when I built the 500 implementation I modeled the "Try again" action in isolation (reload) without tracing the retry semantics. The retry target must be the **original failing URL**, not the error page. The 403 fix already established the pattern (Apollo wrapper appends `?from=<originalPath>`, the view consumes it); I didn't extend that pattern to 500 redirects. Cross-implementation consistency check missed.
- **Correct behavior**:
  1. When any error-page redirect fires, the upstream must append `?from=<encoded original path>` — not just for 403, for every error flow where "retry"/"go back" is a meaningful action.
  2. In the 500 view, read `?from=` via `useSearchParams()` and use it for BOTH the `Resource` row AND the `Try again` action target.
  3. "Try again" should navigate to the original URL (hard navigation via `window.location.assign(from)`) — NEVER `router.push` (stays client-side, bypasses the failing SSR call that caused the 500) and NEVER `window.location.reload()` on the error page (reloads the error page itself).
  4. When `from` is absent or already points back at `/error/*`, fall back to `/dashboard` so the button always has a sensible destination.
  5. Whenever adding or reviewing error flows, check the full chain: upstream redirect caller → URL structure → view handler.
- **Count**: 1
- **Status**: active

### FIX-011 — Claimed "header background removed" after only disabling offset/elevation — missed that ambient bg doesn't extend behind the header
- **Date**: 2026-04-17
- **Mode**: fix (403 header transparency)
- **What happened**: User reported a darker strip behind the header. I diagnosed it as `HeaderSection`'s `::before` blur pseudo activated by `useScrollOffsetTop`, and fixed it by passing `disableOffset` + `disableElevation` + transparent `sx`. But the strip persisted. The real cause: the page's ambient radial/grid Boxes are rendered INSIDE a wrapper that lives in `MainSection` — so they fill the content area only. The header sits ABOVE that wrapper (sticky, transparent) and thus shows the bare body background, not the grid pattern. So the "strip" is actually the ABSENCE of the ambient pattern, not a bg color at all. Declared work complete without testing in-browser or looking at the DOM z-ordering.
- **User correction**: "header background is still not fixed" + screenshot.
- **Root cause**: `assumption-error` + `incomplete-phase` — trusted the first plausible hypothesis (pseudo-element blur) and didn't verify the fix against the actual DOM structure. Should have traced where the ambient Boxes render vs where the header renders before declaring done.
- **Correct behavior**:
  1. When adding ambient/backdrop effects to a layout that has a header, place the ambient either at `position: fixed; inset: 0; zIndex: -1` (viewport-scoped) OR wrap BOTH header and content in a single `position: relative` container so ambient covers everything.
  2. Before claiming a visual fix is complete, diff the DOM stacking: which element is the bg, which is the header, what's between them.
  3. For "a darker strip behind the header" diagnoses, check 3 possible causes before concluding: (a) AppBar bg, (b) pseudo-elements from offset/elevation, (c) **the ambient/decoration not extending behind the header**. (c) is usually the real cause in full-bleed dark layouts.
- **Count**: 1
- **Status**: active

### IMPL-010 — Invented brand treatment inline instead of reading the real brand spec, and didn't extract reusable
- **Date**: 2026-04-17
- **Mode**: fix (403 topbar leftArea)
- **What happened**: Built `BrandBlock` inline in `view-403.tsx` using a shield SVG + `"DAXWELL · SCM"` uppercase wordmark with `0.05em` letter-spacing and a middle-dot separator. The actual brand is a rounded-square green tile with a white `"D"` glyph + `"Daxwell SCM"` in mixed case, no dot. Two separate defects in one shot: (a) the visual didn't match the real brand, and (b) the component was scoped to a single file instead of `packages/ui/src/components/` even though brand marks appear in multiple layouts (simple, dashboard, auth, error pages).
- **User correction**: Screenshot of the correct brand + "logo should be like this and also make it reusable so that we have use everywehre".
- **Root cause**: `assumption-error` + `skipped-component` — invented a plausible brand treatment from design-system tokens (shield icon, primary gradient) without asking or reading any existing brand asset, and placed it inline instead of in the shared components folder despite LR-023 (shared components go to `packages/ui/src/components/`).
- **Correct behavior**:
  1. When the user says "this is the logo/brand", treat the supplied image as the spec — use the glyph shown (`D`), the wordmark text verbatim (`Daxwell SCM`, mixed case, no dot), the exact tile shape.
  2. Brand marks, page headers, shells, avatars, and anything that renders in more than one layout go to `packages/ui/src/components/<name>/` from the first draft. Never start inline and "extract later" — extract now per LR-023.
  3. When an existing shared `Logo` component exists, decide explicitly: replace it, add a sibling variant, or add a prop. Don't silently fork the brand by building a local one.
- **Count**: 1
- **Status**: active

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
- **Status**: [PROMOTED] → LR-012

### IMPL-005 — Replaced AG Grid with custom MUI table when implementing mockup
- **Date**: 2026-04-09
- **Mode**: implement
- **What happened**: When implementing the "Assigned Users" mockup for the role detail users tab, replaced the existing AG Grid table with a custom MUI Box-based table to match the mockup's visual style. The user corrected this — AG Grid is the standard table component in this codebase.
- **User correction**: "use aggrid table"
- **Root cause**: `assumption-error` — Assumed the mockup's clean table look required a custom MUI table. Should have kept AG Grid and used custom cellRenderers to achieve the same visual style. AG Grid is the mandatory table component in this project.
- **Correct behavior**: When implementing a table mockup, always use AG Grid with custom cellRenderers to match the visual design. Never replace AG Grid with a custom MUI table. The mockup defines the look; AG Grid + cellRenderers is the implementation tool.
- **Count**: 1
- **Status**: [PROMOTED] → LR-022

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
- **Status**: active | [PROMOTED] → LR-XXX | obsolete
-->

### IMPL-004 — Duplicated UI block instead of extracting a shared component
- **Date**: 2026-04-03
- **Mode**: implement
- **What happened**: When creating `ProfileBusinessUnits` (modeled after `ProfileRoles`), first copy-pasted only the 60-line user identity banner as a `UserIdentityBanner` component — but missed the bigger picture: the entire assign modal pattern (CreateEditDialogModal + banner + instruction + form slot) was identical. User had to correct twice — first for the banner, then for the full modal.
- **User correction**: (1) "why created again … create component of that and use that everywhere" (2) "why you created only userIdentityBanner, create separate assign modal which should be reusable and then use that accordingly in both"
- **Root cause**: `assumption-error` — Extracted the smallest visible duplication (banner) instead of stepping back to identify the full scope of the duplicated pattern. When two components share an identical modal structure that differs only in title/subtitle/instruction/form-content, the entire modal is the reusable unit, not just one inner zone.
- **Correct behavior**: When told "same as X", identify the **largest reusable boundary** — not just the first obvious block. Ask: "what is the full repeated structure, and what are the only things that vary?" Extract the full pattern as a component with props for the varying parts. In this case: `AssignModal` with props for `title`, `subTitle`, `instruction`, and `children` (the form).
- **Count**: 2
- **Status**: [PROMOTED] → LR-021

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
- **Status**: [PROMOTED] → LR-003

### IMPL-002 — Incomplete mockup implementation: missed visual details across multiple zones
- **Date**: 2026-04-02
- **Mode**: implement
- **What happened**: When implementing the v2 profile mockup, multiple visual details were wrong: role names rendered in ALL CAPS instead of title case, app chips stacked vertically instead of inline, chip text was uppercase, role badge missing star icon, count badge positioned wrong, buttons used wrong variant/icon, table had extra left eye column not in mockup, header had icon box not in mockup.
- **User correction**: "this is what we have but i want exact same as in the mockup" + "learn this that when i ask to implement mockup then always implement whatever is present in mockup"
- **Root cause**: `style-drift` — implemented structural layout correctly but didn't pixel-diff every visual element (text casing, icon choices, chip styles, layout direction, button variants, badge placement) against the mockup. Treated the mockup as a rough guide instead of an exact spec.
- **Correct behavior**: Before submitting, visually diff EVERY element in the mockup against the code: text casing/transforms, icon choices, chip/badge styles, layout direction (row vs wrap), spacing, button variants (outlined vs contained), color tokens, column layout. If the mockup shows title-case but data is uppercase, add a formatter. If mockup shows inline chips, don't allow wrapping. Match it exactly.
- **Count**: 3
- **Status**: [PROMOTED] → LR-002

### STYLE-001 — Failed to auto-format files after editing, causing import order and spacing lint errors
- **Date**: 2026-04-02
- **Mode**: fix
- **What happened**: After editing user-profile-view.tsx, manually rearranged imports to fix lint errors but got the ordering wrong multiple times (type vs value import order, spacing between groups, member sort inside named imports). Each manual attempt introduced new lint errors.
- **User correction**: "after writing code make sure to format code using eslint, that too only on files which you touch"
- **Root cause**: `style-drift` — tried to manually match ESLint import ordering rules instead of running the linter's auto-fix.
- **Correct behavior**: After every file edit, run `pnpm eslint --fix <touched-file>` to let ESLint handle import sorting, spacing, and formatting automatically. Only target the specific files you changed.
- **Count**: 1
- **Status**: [PROMOTED] → LR-001

### IMPL-001 — Kept wrapper modal that conflicts with mockup layout
- **Date**: 2026-04-01
- **Mode**: implement
- **What happened**: Used CreateEditDialogModal as the wrapper when implementing the v2-hero mockup. This added its own header bar (title + close), footer, and DialogContent padding — creating a double-header that doesn't match the mockup's integrated banner design.
- **User correction**: "still not same as mockup avoid create-edit-dialog modal"
- **Root cause**: `assumption-error` — assumed the existing modal wrapper should always be preserved. When a mockup designs its own header/close/footer, the wrapper's chrome conflicts.
- **Correct behavior**: When a mockup has its own header/banner/close/footer that differs structurally from CreateEditDialogModal, use a raw MUI Dialog instead. Replicate permission and loading logic manually.
- **Count**: 1
- **Status**: active
