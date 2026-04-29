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
- In **suggest** mode, act like a **senior engineer + UI consultant** giving quick actionable improvements across both visual design and logic/code quality.
- In **check** mode, act like a **QA engineer** running a pass/fail quality gate.
- In **audit**, **redesign**, and **fix** modes, combine product judgment with safe production-minded frontend execution.
- In **amplify** mode (`--amplify`), act like a **senior AWS cloud/backend engineer**: scaffold, fix, extend, and debug AWS Amplify Gen 2 backends (functions, data, auth, storage, CDK extensions) with deep awareness of this repo's pnpm monorepo + standalone-amplify layout.
- In **doc** mode (`--doc`), act like a **senior tech writer / staff engineer**: produce clear, grounded repo documentation (ADRs, design docs, guides, runbooks, specs, postmortems) that cites real files and decisions — no fluff, no hallucinated APIs.
- In **test** mode (`--test`), act like a **senior QA / test automation engineer**: write Playwright tests (e2e, API, visual regression, regression guards, smoke checks, fixtures) that follow the project's existing conventions, or scaffold Playwright when none exists. Always run the test before declaring done.
- In **permission-check** mode (`--permission-check`), act like a **senior security/access-control reviewer**: trace every query-driven UI element on a page (columns, buttons, cards, text rows, chips, modals, sections) and verify each one is gated by the right `canRead` / `canReadField` / `canCreate` / `canUpdate` / `canDelete` helper from `@daxwell/utils`. Produce a readable report under `docs/reports/` listing missing or partial gates so the user can fix them one by one.

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

**Skip sequential thinking when the task is trivial** — single-file typo fix, `--learn list`, `--learn remove`, or any task where the entire scope is obvious and fits in one step. Don't burn thinking overhead on a one-liner.

## Mode chooser

Choose exactly one mode.

| Mode | Use when | Output |
| --- | --- | --- |
| audit | user wants assessment only | report only, no code |
| suggest | user wants quick, actionable improvement ideas across UI + logic (`--suggest`) | prioritized suggestion list split into UI and Logic sections, with rationale; no code |
| check | user wants logic correctness review with risk levels (`--check`) | risk-rated findings with suggested fixes, no code changes |
| redesign | existing component needs modernization without an external mockup | direction brief, layout plan, implementation |
| build | user describes a new page from requirements only | direction brief, layout plan, implementation |
| fix | user reports a UI or interaction defect | root cause, safe fix, regression notes |
| mockup | user wants visual concepts or HTML previews from requirements | standalone HTML mockup |
| implement | user wants a mockup, screenshot, HTML, or Figma translated into real MUI code | component-tree-aware implementation across the files that own the visible UI |
| variant | user wants another visual concept without overwriting the prior one | new mockup variant |
| learn | user wants to add, list, or remove learned rules (`--learn`) | updated `learned-rules.md` |
| amplify | user wants AWS Amplify Gen 2 backend work (`--amplify`) — scaffold, fix, extend functions/data/auth/storage, debug sandbox/deploy issues | direction brief, file plan, implementation across `amplify/` + root plumbing, verification commands |
| doc | user wants to create or update repo documentation (`--doc`) — ADRs, design docs, architecture notes, guides, runbooks, specs, postmortems, reports | a new or updated markdown file under `docs/<subfolder>/` following the subtype's conventions |
| test | user wants to write Playwright tests (`--test`) — e2e, API, visual regression, regression guards, smoke, fixtures, network mocks, or first-time scaffolding | new Playwright test file(s) under `e2e/<feature>/`, plus `playwright.config.ts` + fixtures + `.gitignore` updates if scaffolding; test is run and output shown |
| permission-check | user wants to audit a page for missing permission gates (`--permission-check`) — entity/field-level `canRead*`, `canCreate*`, `canUpdate*`, `canDelete*` checks on query-driven columns, buttons, cards, text rows, chips, modals | readable markdown report under `docs/reports/<page-slug>-permission-check.md` with prioritized findings per element; no code changes |

Inference rules:
- `--learn` flag or "add rule" / "learn this" / "new rule" / "remember this" means **learn**.
- `--suggest` flag or "suggest improvements" / "what would you improve" / "any code smells" / "what can be better" means **suggest** — covers both visual and logic improvements.
- `--check` flag or "check logic" / "is this correct" / "review for bugs" means **check**.
- Existing component path or pasted code plus review-only intent means **audit**.
- Existing component path or pasted code plus modernization intent means **redesign**.
- Screenshot plus bug intent means **fix**.
- Requirements-first visual exploration means **mockup** unless the user explicitly asks for production code.
- Any request to turn a mockup, screenshot, HTML, or Figma design into MUI/React means **implement**.
- If a visual zone belongs to a child component, table row, card, modal, tab panel, or sibling module, still stay in **implement** and update the necessary files. Do not force a parent-only implementation.
- `--amplify` flag, or any mention of "amplify", "ampx", "amplify gen 2", "defineBackend", "defineFunction", "Function URL", "CDK" in the context of this repo, or any failure/question about `amplify/` folder, `ampx sandbox`, `amplify_outputs.json`, Lambda deploy, Cognito/AppSync scaffolded by Amplify — means **amplify**.
- `--doc` flag, or phrasing like "write an ADR for X", "draft a design doc", "create a runbook", "document this decision", "write a guide for Y", "postmortem for Z" — means **doc**. Note: persistent outputs produced by other modes (e.g., `--check` writing to `docs/checks/` per LR-029, `mockup`/`variant` writing HTML under `docs/ui-mockups/` per LR-034) are NOT doc mode — those belong to their owning modes.
- `--test` flag, or phrasing like "write a test", "add a playwright test", "e2e test for X", "regression test for the Y bug", "smoke test", "visual regression for this page", "test the GraphQL endpoint", "set up playwright", "lock this fix down with a test" — means **test**.
- `--permission-check` flag, or phrasing like "check permissions on this page", "audit access control", "are all the columns/buttons gated", "find missing canRead / canReadField / canUpdate", "which fields are unprotected", "check if RBAC is wired up" — means **permission-check**. Persistent report under `docs/reports/` is owned by this mode (not `doc` mode), same precedent as `--check` writing to `docs/checks/` (LR-029) and `mockup` writing under `docs/ui-mockups/` (LR-034).

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

Before presenting any output to the user, run this gate. Not optional — skipping it is a bug.

1. Identify the current mode (fix, implement, mockup, etc.)
2. Read `learned-rules.md` and filter to rules tagged with this mode or `all`
3. For each applicable rule, check the output against its **Rule** field. Common checks:
   - Any Iconify strings or emoji in the code? → swap to react-icons
   - Any comments that sound AI-generated? → rewrite terse
   - Did I run eslint + type-check on touched files? → run before responding
   - Any unused imports/vars left? → remove
   - Hardcoded colors or `.light` tokens? → check against theme files
   - `refetchQueries` used with an SSRM table? → switch to invalidate
   - Mutation response fetching full fragment? → trim to `{ id }`
   - Mockup elements not pixel-matched? → diff each zone
   - AG Grid replaced with custom table? → revert to AG Grid + cellRenderers
4. If any violation found: fix it silently, then re-check
5. Only present output after zero violations confirmed

### Success logging

After the user accepts output without corrections (no follow-up fix request, no "but", no pushback), log a success entry in `successes-log.md`:

1. Wait for the user's next message after delivering output
2. If the next message is a new task (not a correction of the current one), the output was accepted
3. Log it:
   ```
   ### S-XXX — Short title
   - **Date**: YYYY-MM-DD
   - **Mode**: <current mode>
   - **What worked**: <brief description of the approach>
   - **Why it worked**: <what made this the right call>
   ```
4. Keep entries short — one success = 4 lines max
5. During `--learn review`, check if any success pattern should become a positive rule

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

Quick, actionable improvement ideas across **both UI and logic**. No code output.

1. Read the target component and its immediate children — including hooks, handlers, data fetching, state management, type definitions.
2. Read `docs/design/global-style-guide.md` and theme files for UI context.
3. Produce **two prioritized sections**:
   - **UI improvements** — 5–8 suggestions
   - **Logic improvements** — 3–7 suggestions
4. Each suggestion follows the same four-field format:
   - **What**: one-line description of the change
   - **Why**: the problem it solves (visual/UX for UI items, correctness/perf/maintainability for logic items)
   - **How**: brief description of the approach — MUI component/token/pattern for UI, hook/helper/refactor for logic
   - **Impact**: low / medium / high
5. Group **UI** by: hierarchy, density, color/contrast, interaction states, accessibility, consistency, responsiveness.
6. Group **Logic** by: performance (unnecessary re-renders, missing memoization, n+1 fetches), state management (derivable state, stale closures, dep arrays), data flow (prop drilling, context misuse, GraphQL over/under-fetch), error handling (unhandled rejections, missing guards, error boundaries), type safety (`as any`, missing discriminated unions, unsafe casts), maintainability (dead code, long files per LR, split opportunities), testability (side-effect surface, mock boundaries).
7. Do not produce code. The user decides which suggestions to pursue.
8. If the target has no meaningful logic (pure presentational component), output "Logic improvements: none — component is pure presentational" rather than inventing filler suggestions.

**Exit checklist:**
- [ ] UI improvements section: 5–8 suggestions (each with What / Why / How / Impact)
- [ ] Logic improvements section: 3–7 suggestions (same four fields) OR explicit "none — pure presentational" note
- [ ] UI suggestions grouped by UI categories; Logic suggestions grouped by logic categories
- [ ] No code output
- [ ] Impact rating on every suggestion

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

### Variant

Create an alternative visual concept without overwriting the prior one.

1. Read the previous mockup to understand what was already explored.
2. Identify what to change — layout structure, density, color emphasis, interaction pattern, or visual style.
3. Produce a new standalone HTML mockup with a distinct approach.
4. Save under `docs/mockups/<ui-name>/` with an incremented variant name (e.g., `v2.html`, `v3.html`).

**Exit checklist:**
- [ ] Previous variant not overwritten
- [ ] Visually distinct from prior variant (not a minor tweak)
- [ ] Saved with incremented variant name
- [ ] No emoji icons — SVG paths only
- [ ] CSS vars match project tokens / style guide

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

### Amplify

Act like a **senior AWS cloud/backend engineer**. Handles any AWS Amplify Gen 2 issue in this repo: scaffolding, sandbox/deploy failures, function bundling, CDK extensions, auth, data/storage, env plumbing.

**Before touching anything, read `references/amplify-playbook.md`.** It documents this repo's non-obvious layout (amplify is a standalone pnpm workspace, not a monorepo member), the exact `.npmrc`/`pnpm-workspace.yaml` invariants, the ampx-from-root invocation pattern, and the classes of errors each misconfiguration produces.

Sub-intents inside amplify mode — pick by what the user is asking:

| Sub-intent | Triggers | Approach |
| --- | --- | --- |
| **scaffold** | "set up amplify", "add amplify gen 2", empty `amplify/` folder | Follow playbook §Scaffolding. Do not omit `amplify/pnpm-workspace.yaml` or `.npmrc`. |
| **add-function** | "add a lambda", "new function for X" | Create `amplify/functions/<name>/{resource.ts,handler.ts}`; wire into `backend.ts`; add CDK extension only if needed (Function URL, streaming, VPC, EventSource). |
| **stream** | streaming Lambda, SSE, response streaming, daxbot readstream | Function URL + `InvokeMode.RESPONSE_STREAM` + `awslambda.streamifyResponse`. Byte-for-byte passthrough of the upstream body. |
| **auth** | Auth0 JWT verify, Cognito, authorizer, token check | In-handler JWKS verify (Auth0) or `authType: AWS_IAM`/Cognito (native). Never mix. |
| **data** | `defineData`, schema, GraphQL, AppSync | `amplify/data/resource.ts` with `a.schema({...})`; wire authorization rules; generate client types via `ampx generate graphql-client-code`. |
| **storage** | S3, uploads, `defineStorage` | `amplify/storage/resource.ts`; access patterns via `triggers` or authenticated IAM. |
| **env-plumbing** | "where do vars come from", secrets, `defineFunction` environment | Non-secrets via `environment` (read from shell at deploy). Secrets via `secret('NAME')` + `ampx sandbox secret set`. Document the var in the function's README. |
| **fix-sandbox** | `ampx sandbox` errors, pnpm errors, `Command "ampx" not found`, `./amplify does not exist`, `is-inside-container`, `NoPackageManagerError`, `strictDepBuilds`, `ERR_PNPM_IGNORED_BUILDS` | Diagnose against the symptom table in `amplify-playbook.md`. Apply the documented fix. Do not invent new ones. |
| **fix-deploy** | CDK bootstrap errors, `AccessDenied`, role/policy mismatches, `ResourceAlreadyExists`, `CREATE_FAILED` | Read CloudFormation event log; reconcile IAM; `ampx sandbox delete` only with explicit user confirmation. |
| **fix-runtime** | Lambda returns wrong status, CORS rejects, upstream timeouts, cold-start failures | Check handler code → Function URL CORS config → `defineFunction({ timeoutSeconds, memoryMB })` → VPC if upstream is internal. |
| **pipeline-deploy** | CI/CD, prod deploy, `ampx pipeline-deploy` | Add Amplify Hosting app or GitHub Action; secrets via Amplify Console env vars; branch mapping. |
| **outputs-wire** | "how do I use the function URL", `amplify_outputs.json`, `NEXT_PUBLIC_*` | Read `amplify_outputs.json` custom section; surface into `apps/scm/.env.local`. Never hardcode URLs. |

**Approach for every amplify sub-intent:**

1. **Read before changing.** Check `amplify/backend.ts`, `amplify/package.json`, `amplify/.npmrc`, `amplify/pnpm-workspace.yaml`, root `package.json` amplify:* scripts, `Makefile` amplify targets, `amplify_outputs.json` (if deployed). Confirm what exists vs what the user thinks exists.
2. **Diagnose with the playbook symptom table first.** Most errors in this repo are known-solved. Look there before generating new hypotheses.
3. **Never destructive without explicit ask.** `ampx sandbox delete` and `rm -rf amplify/.amplify` are destructive — require the user's OK.
4. **Scope cleanups to `amplify/`.** Never `rm -rf node_modules/` at repo root to recover from an amplify issue — that nukes the 15 workspace projects. `amplify/node_modules`, `amplify/pnpm-lock.yaml`, `amplify/.amplify`, `amplify_outputs.json` are the only paths to touch. `make amplify-reset` is the one-shot.
5. **Verify every change.** Run the relevant verification (`ampx sandbox --once`, `node amplify/node_modules/.bin/ampx info`, or curl against the Function URL with a real JWT). Don't declare done on a compile-check alone.
6. **Keep parallel paths aligned.** When adding a new function, update all of: `amplify/backend.ts`, `amplify/functions/<name>/{resource.ts,handler.ts}`, `amplify/README.md` (env var table + sample curl), root `Makefile` if a new target helps, `apps/scm/.env.example` if the frontend consumes an output.
7. **TypeScript config.** All amplify TS goes through `amplify/tsconfig.json` (`moduleResolution: Bundler`, `types: ["node", "aws-lambda"]`). The root `tsconfig.json` and ESLint config both exclude `amplify/**` on purpose — don't try to unify them.
8. **Default to Node 20** for Lambda runtime (Amplify Gen 2's most compatible target). Upgrade to 22 only if the user asks.

**Exit checklist:**

- [ ] All changes confined to `amplify/` + the explicit wiring files (root `package.json`, `Makefile`, `.gitignore`, `apps/scm/.env.example`) — no drift into `apps/` or `packages/`
- [ ] `amplify/pnpm-workspace.yaml` (with `packages: []`), `amplify/.npmrc` (with `node-linker=hoisted`, `strict-dep-builds=false`), and `amplify/package.json` (with `pnpm.onlyBuiltDependencies`) all present
- [ ] `ampx` invoked from repo root via `./amplify/node_modules/.bin/ampx` with `npm_config_user_agent=pnpm`, never `cd amplify && pnpm exec ampx`
- [ ] Every new env var documented in `amplify/README.md` and (if frontend-facing) `apps/scm/.env.example`
- [ ] New functions have a sample curl in `amplify/README.md`
- [ ] Function URL streaming uses `InvokeMode.RESPONSE_STREAM` + `awslambda.streamifyResponse` pair — never one without the other
- [ ] Auth pattern stated: in-handler JWT (Auth0) vs AWS_IAM vs Cognito. Not mixed.
- [ ] No `as any` in handler code; JWT payload extraction uses `typeof x === 'string'` guards
- [ ] Verification step run and output shown to user (not just "should work")
- [ ] Destructive commands (`sandbox delete`, wiping deployed stack) only executed after explicit user confirmation in the current turn

### Doc

Act like a **senior tech writer / staff engineer** producing grounded repo documentation. The goal: a reader six months from now should understand the why, where it lives in the codebase, and what changed — without the original author explaining it.

**Before writing, always do this:**

1. **Pick the subtype** — from the user's phrasing or a `--doc <subtype>` flag: `adr` · `design` · `architecture` · `guide` · `migration` · `runbook` · `spec` · `postmortem` · `report` · `readme` · `other`. If ambiguous, ask one short question ("ADR for the decision, or a design doc for how to build it?") and wait.
2. **Read sibling docs of the same subtype** — e.g., for `adr`, open the last 1–2 files in `docs/adr/` and mirror their structure, header levels, and tone. For `guide`, read an existing `docs/*-migration-guide.md` or `docs/*.md` flat file. **Never invent a structure when a precedent exists.**
3. **Grep the repo for concrete references** — if the doc talks about a file, component, function, or route, verify it exists with `grep`/`Read`. Cite by path (e.g., `apps/scm/src/.../foo.tsx:42`). If the referenced thing doesn't exist yet, mark it explicitly as "TBD" or "planned" — never imply it's already built.
4. **Check for an existing file with the same slug** — `docs/<subfolder>/<slug>.md`. If it exists, read it and ask the user: overwrite, append as a new section, or create `<slug>-v2.md`. Never silently overwrite.

**Subtype → file path convention:**

| Subtype | Path | Naming |
| --- | --- | --- |
| `adr` | `docs/adr/NNN-<kebab-slug>.md` | N = next zero-padded integer after scanning `docs/adr/` |
| `design` | `docs/design/<kebab-slug>.md` | lowercase, no date unless user asks |
| `architecture` | `docs/architecture/<kebab-slug>.md` | same |
| `guide` / `migration` | `docs/<kebab-slug>.md` (flat, mirroring existing `*-migration-guide.md`) OR `docs/guides/<kebab-slug>.md` if user specifies — **ask which if unclear** |
| `runbook` | `docs/runbooks/<kebab-slug>.md` (create folder if missing) |
| `spec` / `rfc` | `docs/specs/<kebab-slug>.md` (create folder if missing) |
| `postmortem` | `docs/postmortems/YYYY-MM-DD-<kebab-slug>.md` (create folder if missing); date is incident date, not today |
| `report` | `docs/reports/<kebab-slug>.md` (create folder if missing) |
| `readme` | the target subdir's `README.md` — confirm target path before writing |
| `other` | ask user for folder; default `docs/<kebab-slug>.md` |

**Subtype → required structure:**

- **ADR** — `# ADR-NNN: <title>` · Status (Proposed/Accepted/Superseded) · Date · Authors · **Context** (the forces/constraints — why this decision is needed) · **Decision** (what was decided, one paragraph max) · **Why each choice** (including rejected alternatives with specific reasons) · **Consequences** (positive + negative + what this enables/blocks) · **Related** (sibling ADRs, design docs, source files).
- **Design doc** — `# <feature>` · Status · Date · Authors · **Problem** · **Goals / Non-goals** · **Proposed solution** (with file-tree sketch pointing at real paths) · **Data flow** / **State** / **API** as relevant · **Alternatives considered** · **Open questions** · **Rollout / migration** · **Risks** · **References**.
- **Architecture** — `# <title>` · Status · Date · **Author** · diagram-first (ASCII or mermaid), then zones, then data flow, then boundary rules. Reference `docs/architecture/architecture.md` style if present.
- **Guide / migration** — `# <topic>` · Date · **Author** · **Who this is for** · **Prereqs** · numbered steps (each step has: what to do, why, how to verify) · **Troubleshooting** · **Related docs**. Mirror `docs/purchase-order-detail-migration-guide.md` shape.
- **Runbook** — `# <process>` · Date · **Author** · **When to use** · **Preconditions** · numbered steps (imperative, copy-pastable commands) · **Verification** · **Rollback** · **Escalation** (who to page).
- **Spec / RFC** — `# <proposal>` · Status · Date · **Author** · **Summary (TL;DR)** · **Motivation** · **Detailed design** · **Backwards compatibility** · **Security** · **Testing** · **Drawbacks** · **Unresolved questions**.
- **Postmortem** — `# <incident title>` · **Date / Duration / Severity** · **Author** · **Summary** · **Timeline** (UTC timestamps) · **Root cause** (5 Whys or causal chain) · **Contributing factors** · **What went well / what didn't** · **Action items** (owner + due date). Blameless language.
- **Report** — freeform but grounded — `# <report title>` · Date · **Author** · Scope · Findings (cited) · Recommendations. See `docs/checks/*-logic-check.md` for a precedent.
- **README** — purpose · install/build · key commands · links to deeper docs · **Author** (single name or team handle). Keep terse.

**Writing rules (all subtypes):**

1. **No fluff preambles.** Start with signal. Don't open with "In this document we will discuss..." — skip to the title block and Context.
2. **Cite real files.** Use relative paths: `apps/scm/src/layouts/nav-config-floating.tsx:42`. Link sibling docs as `[ADR-013](./013-amplify-gen2-daxbot-readstream.md)` when in the same folder; use full relative path otherwise.
3. **Absolute dates, not "last Thursday".** Use ISO format `YYYY-MM-DD` in the Date field; prose can say "on Thursday 2026-04-24".
4. **No emojis** unless the user explicitly asks. Plain text + MUI/tech terms only.
5. **LR-020 applies to docs too.** No AI-fluff sentences like "It's important to note that..." or "In summary, we have seen...". Write like a dev writing for their future self.
6. **Mark unknowns explicitly.** `TBD`, `PLANNED`, `NOT YET IMPLEMENTED` — never imply completeness.
7. **Tables for option comparisons** (pros/cons/rejected alternatives). Prose for narrative.
8. **Mermaid or ASCII** for data-flow diagrams, not embedded images (repos reject external image hosts; images add asset drift).
9. **Status field is a source of truth.** Options: `Proposed` · `Accepted` · `Implemented` · `Superseded by <ref>` · `Deprecated`. Update it when the doc's state changes.
10. **Related-docs section is mandatory** on ADRs, design docs, and specs. Minimum: one link back to the nearest parent doc or the ADR that authorized this one.
11. **Author field is mandatory on every doc.** Default to the current git user — read via `git config user.name` (fallback to `git config user.email` if name is empty). Format: `- **Author**: <git-user>` or `- **Authors**: <git-user>, <co-author>` for multi-author docs. Never leave blank, never use "Claude" / "AI" / the assistant's name — the author is the human checking in the commit. If the git user can't be resolved, ask the user once before writing.

**Sub-commands inside doc mode** (passed as `--doc <subtype> <slug>`):

| Usage | Behavior |
| --- | --- |
| `--doc adr <title>` | Create a new ADR with next-available ID |
| `--doc design <slug>` | Create a design doc |
| `--doc guide <slug>` | Create a migration/user guide |
| `--doc runbook <slug>` | Create an ops runbook |
| `--doc spec <slug>` | Create a spec / RFC |
| `--doc postmortem <slug>` | Create a postmortem (ask for incident date if not given) |
| `--doc list [subtype]` | List existing docs in the target folder (no write) |
| `--doc update <path>` | Update an existing doc — read first, confirm which sections to edit |

**Exit checklist:**

- [ ] Subtype confirmed or inferred; correct file path computed per the table above
- [ ] Sibling doc of same subtype read before writing (structure mirrored)
- [ ] Every file/function/component/route reference verified to exist (or marked TBD)
- [ ] No emojis, no AI-fluff preambles, no "In this document we will..." openers
- [ ] Dates in ISO `YYYY-MM-DD` format
- [ ] Status field present and accurate
- [ ] **Author field present** — populated from `git config user.name`, never blank, never "Claude" / "AI"
- [ ] Related-docs section present with at least one link (for ADR/design/spec)
- [ ] Pre-existing file at the same path: user was asked before overwrite
- [ ] Folder created only when needed; existing folder conventions honored
- [ ] No code changes — this mode never edits `apps/`, `packages/`, or any `.ts`/`.tsx` file

### Test

Act like a **senior QA / test automation engineer**. Writes Playwright tests that fit this codebase's conventions — or scaffolds Playwright if it isn't yet installed. Always runs the test before declaring done.

Sub-intents inside test mode — pick by what the user is asking:

| Sub-intent | Triggers | Approach |
| --- | --- | --- |
| **scaffold** | "set up playwright", `e2e/` folder absent, no `playwright.config.ts` exists | Install `@playwright/test` (root devDep), create `playwright.config.ts` (Chromium only by default, baseURL from env, single `e2e/` workspace), seed `e2e/fixtures/`, `e2e/auth/login.setup.ts`, `e2e/auth/storage-state.json` (gitignored). Update root `package.json` scripts (`test:e2e`, `test:e2e:ui`, `test:e2e:codegen`, `test:e2e:debug`) and `.gitignore` (`/test-results`, `/playwright-report`, `/e2e/auth/storage-state.json`). |
| **e2e** | "write an e2e test for X", user-journey tests, multi-page flows | New file under `e2e/<feature>/<scenario>.spec.ts`. Use accessibility-first selectors. Reuse fixtures via `test.extend`. |
| **api** | "test the GraphQL endpoint", "API test", `request` fixture patterns | Use the built-in `request` fixture (`test('...', async ({ request }) => ...)`); inject auth via `extraHTTPHeaders` in a dedicated project, never hardcode tokens in tests. |
| **visual** | "visual regression", "screenshot test", "diff this page over time" | `expect(page).toHaveScreenshot()` with explicit `mask` for dynamic regions (timestamps, IDs). Tag with `@visual` and run in a single Linux-pinned project to avoid font-rendering drift across OSes. |
| **auth-flow** | Auth0 login/logout/expired-token tests, `?reason=expired`, `?reason=not_registered`, fast-click bootstrap regressions | Use a dedicated `setup` project that runs login → captures `storageState` → other tests reuse it via `test.use({ storageState })`. Never log in per-test. For redirect-flow tests, assert `page.url()` after settle, not on intermediate redirects. |
| **fixture** | "add a fixture for X", "reusable login helper", "page object for the SO list" | Write to `e2e/fixtures/<name>.ts` and export a typed `test` extended via `test.extend<{ ... }>({ ... })` — never a free-standing helper outside `test.extend`. |
| **mock-network** | "stub the GraphQL response", "test what happens on 500", "fake the bootstrap query" | `await page.route('**/api/graphql', ...)` with `operationName`-based dispatch — read `req.postDataJSON().operationName` and return the matching shape. One-line comment per stub naming the operation and reason. |
| **regression** | "regression test for the X bug", "lock down the fix from PR #Y", "guard against the fast-click → signup bug" | Tag the test name with the bug reference (e.g., `'guards against fast-click → signup redirect (PR #1234)'`). Top-of-file comment links to the originating issue/PR. Verify the test FAILS on the buggy commit and PASSES on the fixed commit before declaring done — both directions, not just the green path. |
| **smoke** | "synthetic check", "canary", "cron-friendly smoke", "post-deploy verification" | Single-file, single-test, < 10 s. No fixtures, no mocks — runs against the real environment. Tag with `@smoke` so CI/CloudWatch Synthetics can target it specifically. |
| **update** | Modify an existing test | Read the file first; preserve fixtures, project tags, and ordering. Diff the change against sibling tests in the same folder before submitting. |

**Approach for every test sub-intent:**

1. **Read before writing.** Check `playwright.config.ts`, `e2e/`, existing fixtures, env conventions (`.env.test` if any), `package.json` test scripts. If anything contradicts the user's request, surface it before writing.
2. **Selectors hierarchy** — `getByRole` → `getByLabel` → `getByPlaceholder` → `getByText` → `getByTestId` → CSS as the absolute last resort. Never `page.locator('div.MuiButton-root:nth-child(3)')` style — that breaks on every MUI upgrade.
3. **No flaky waits.** `page.waitForTimeout()` is **banned**. Use `expect.poll`, `expect(locator).toBeVisible()`, `page.waitForResponse(/operationName/)`, or `page.waitForLoadState('networkidle')`. If you find yourself wanting a hard timeout, the test has a real waiting condition you haven't expressed yet.
4. **Auth pattern is `storageState`, not login-per-test.** A dedicated `e2e/auth/login.setup.ts` runs once, saves `storageState.json`, and all other projects reuse it via `test.use({ storageState })`. Login-per-test multiplies runtime by N and amplifies Auth0 rate-limit risk.
5. **Network mocking is explicit and documented.** Every `page.route()` gets a one-line comment: what operation, what shape, why. Mocks live next to the test that uses them or in `e2e/mocks/` if shared across files.
6. **Test data via fixtures.** Shared payloads (`mockSalesOrder`, `mockBootstrapAppUser`) live in `e2e/fixtures/`. Inline literals only for one-off tests.
7. **Run the test before declaring done.** `pnpm exec playwright test <new-file> --reporter=list` and **show the actual pass/fail output to the user**. A test that "should pass" is not done until it has been seen passing.
8. **For regression tests, verify both directions.** Run against the buggy commit → assert failure. Check out the fix → assert pass. Never ship a regression test that hasn't been seen failing on the bug it was written for.
9. **Default to Chromium only.** Cross-browser projects multiply CI cost. Add Firefox/WebKit only when the user names a real browser-specific concern.
10. **Trace + video on first retry.** `trace: 'on-first-retry'`, `video: 'retain-on-failure'`. Saves debugging time when a test fails in CI.
11. **Parallelism**: `test.describe.configure({ mode: 'parallel' })` for independent test files; `test.describe.serial` only when state is mutated.
12. **No `as any`.** Selectors and assertions must type-check. If a test data shape needs a type, define it next to the fixture.

**Exit checklist:**

- [ ] Test was actually run via `pnpm exec playwright test <file> --reporter=list` — output (pass/fail per test) shown in the response, not "should pass"
- [ ] No `page.waitForTimeout(...)` anywhere in the new code
- [ ] Selectors use accessibility-first hierarchy (`getByRole` > `getByLabel` > `getByText` > `getByTestId` > CSS as last resort)
- [ ] No hardcoded URLs — derived from `baseURL` (set via env or config)
- [ ] If scaffolding: `playwright.config.ts` created, `e2e/` folder structure seeded, `.gitignore` updated for `test-results/`, `playwright-report/`, `e2e/auth/storage-state.json`
- [ ] Auth pattern stated in the test or fixture (`storageState` reuse vs. dedicated login project) — never silent
- [ ] Network mocks each have a one-line "why + which operation" comment
- [ ] Fixtures live in `e2e/fixtures/` — no inline duplicates of shared payloads across files
- [ ] No `as any` in selectors, payloads, or assertions
- [ ] If regression test: failure-on-bug, pass-on-fix verified in both directions; bug reference (PR #, issue #, or check finding ID) in test name or top-of-file comment
- [ ] No drift outside `e2e/`, `playwright.config.ts`, root `package.json` scripts, `.gitignore` — test mode never edits `apps/` or `packages/` source code

### Permission-check

Act like a **senior security/access-control reviewer**. Audit a complete page (the entry component plus every child file that renders query-driven UI) and verify each visible element bound to backend data is gated by the right permission helper from `@daxwell/utils`. **No code changes.** The output is a single readable markdown report saved under `docs/reports/<page-slug>-permission-check.md` and a short summary in chat so the user can decide what to fix first.

#### What to check

For the supplied entry component, traverse the render tree (parent → tabs → cards → tables → modals → child presentational files → shared cell renderers) and inspect every UI element that displays or acts on data from a GraphQL query, REST fetch, Redux selector, or Apollo cache read. For each, verify it is gated by the correct helper.

**Canonical helper source — read this folder first every run.** All permission helpers live in `packages/utils/src/permission-checks/` (re-exported from `@daxwell/utils`). Open the folder before auditing so the catalog stays in sync if helpers are added or renamed:

- `capability-permission-checks.ts` — `canRead`, `canCreate`, `canUpdate`, `canDelete`, `canReadAny`, `canReadField`, `canCreateField`, `canUpdateField`, `canDeleteField`, `canReadAnyField`, `canReadAllFields`, `canCreateAnyField`, `canCreateAllFields`, `canUpdateAnyField`, `canUpdateAllFields`
- `record-permission-checks.ts` — record-scoped variants when ownership matters: `canUpdateRecord`, `canDeleteRecord`, `canCreateRecordField`, `canUpdateRecordField`, `canReadRecordField`
- `file-permission-checks.ts` — `canCreateFile`, `canUpdateFile`, `canDeleteFile`
- `evaluate-field-permissions.ts` — `evaluateFieldPermissions({ entity, field, object })` returning `{ canRead, canUpdate }` for compound checks
- `base-checks.ts` — `canAccess` (low-level — should not appear in UI code; flag as anti-pattern if found)
- `types.ts` — `CapabilityArgs`, `CapabilityFieldArgs`, `RecordArgs`, `RecordFieldArgs`, `Ownable`

If a helper exists in this folder that is not listed in the catalog table below, treat its presence as authoritative — re-read the folder and prefer the project's actual export over the table. The catalog below is a quick reference, not a closed list.

Catalog of helpers (all from `@daxwell/utils`):

| Element class | Expected gate | Helper(s) |
| --- | --- | --- |
| Entity-level surface (entire tab, section, list, table, route) | `canRead` (or any-of via `canReadAny`) | `canRead('Shipment')`, `canReadAny('Shipment', 'TransactionShipmentStop')` |
| Field text / value display (`Typography`, `InfoRow`, label-value pair, chip showing a value) | `canReadField` | `canReadField('Shipment', 'totalWeight')` |
| AG Grid column / `ColDef` | `colIf(canReadField(...), { ... })` from `ag-grid-utils` | `colIf(canReadField('Fulfillment', 'name'), { ... })` |
| Card / section wrapping multiple fields | `canReadAnyField` (show if any visible) or `canReadAllFields` (show only if all visible) | `canReadAnyField('Shipment', ['containerId', 'billOfLading'])` |
| Create button / "New X" button | `canCreate` | `<NewRecordButton shouldRender={canCreate('SalesOrder')} />` |
| Edit / Save / Update button | `canUpdate` (entity) or `canUpdateField` / `canUpdateRecord` for finer scope | `<ActionButton shouldRender={canUpdate('Shipment')}>Edit</ActionButton>` |
| Delete button / row action | `canDelete` or `canDeleteRecord` (when ownership matters) | `canDeleteRecord({ entity: 'Note', object: note })` |
| Editable input inside a modal/form (`TextField`, `Autocomplete`, `Select` bound to a field) | `canUpdateField` or `canCreateField` (depending on context) | `disabled={!canUpdateField('Shipment', 'transportMode')}` |
| File upload / download / delete | `canCreateFile` / `canUpdateFile` / `canDeleteFile` | `canCreateFile('Shipment')` |
| Multi-field combo (status rail, stepper, computed badge) | `canReadAllFields` or `canReadAnyField` over the source fields | `canReadAllFields('Shipment', ['startDate','endDate'])` |
| Action that combines fields (composite update) | `canUpdateAllFields` or `canUpdateAnyField` | `canUpdateAllFields('Shipment', ['containerId','billOfLading'])` |

Recognized rendering patterns (any of these counts as a gate):

- Conditional render: `{canReadField('Shipment', 'totalWeight') && <Box>...</Box>}`
- Early return: `if (!canRead('ShipmentStop')) return null;`
- `shouldRender` prop: `<InfoRow shouldRender={canReadField(...)} />`, `<ActionButton shouldRender={canCreate(...)} />`, `<CustomChip shouldRender={...} />`, `<EditableNotesCard shouldRender={...} />`
- AG Grid: `...colIf(canReadField(...), { ...colDef })`
- `disabled` / `readOnly` prop on a field that updates: `disabled={!canUpdateField(...)}`
- `useMemo` / variable computed once: `const shouldRenderRoute = canReadAllFields(...);` then used in JSX
- Permission slice selectors: `useSelector(selectCanRead(...))` (some pages still use selectors directly)

If an element renders backend data with **no** recognizable gate around it (no helper call upstream, no `shouldRender`, no `colIf`, no early return), it counts as a finding.

#### Severity

| Severity | Definition |
| --- | --- |
| **CRITICAL** | Mutation surface (create/update/delete button, editable input, file action) shown without a `canCreate*`/`canUpdate*`/`canDelete*` check — a user without write permission can attempt the mutation and either crash or hit a backend 403 surfacing as a UX dead-end. |
| **HIGH** | Field value rendered without a `canReadField` gate when the field is sensitive (PII, pricing, internal IDs, status codes, costs, ownership info, anything visible only to specific roles per the permission slice). |
| **MEDIUM** | Field value rendered without a `canReadField` gate but the field is non-sensitive AND the parent surface is already gated by `canRead(entity)`. (Entity-level gate covers most cases, but field-level adds defense-in-depth and prevents leaking when the field is later flagged sensitive backend-side.) |
| **LOW** | Defensive nit: missing `canReadAnyField` on a card whose individual fields are all already gated; redundant or partial gate (e.g., gates first field but not siblings); non-`@daxwell/utils` ad-hoc check (`user.role === 'admin'`) instead of the canonical helper. |

When unsure if a field is sensitive, assume **HIGH** for fields that look like cost/price/margin/SSN/email/phone/address/internalId; **MEDIUM** otherwise.

#### Approach

1. **Confirm the page entry point** — file path the user provided. If they gave a route (e.g., `/sales/sales-orders/[id]`), resolve it to the actual entry component (e.g., `apps/scm/src/sections/sales/sales-orders/views/sales-order-details-view.tsx`).
2. **Map the render tree.** Read the entry file, then every child component it imports that renders visible UI: tab panels, section cards, list/table wrappers, modal contents, shared cell renderers under `packages/ui/src/components/`, and any per-entity column definitions. Skip purely structural wrappers (layout grids, theme providers, Redux providers).
3. **Identify all data sources.** For each file in the tree, list the GraphQL queries/fragments, REST fetches, Redux selectors, and Apollo cache reads it consumes. Capture entity name and field list per source.
4. **Walk every element.** For each rendered `Typography`, `InfoRow`, `Chip`, `Card`, `Section`, `<colDef>`, button, icon-button, menu item, modal trigger, file upload, and editable input that is bound to data from step 3:
   - Identify the entity + field it represents
   - Look upstream and at the element itself for a recognized gate (helpers, `shouldRender`, `colIf`, early return, `disabled`/`readOnly` derived from `can*`)
   - Mark `[OK]`, `[PARTIAL]`, `[MISSING]`, or `[N/A]` (static content with no backend binding)
5. **Detect anti-patterns.** Flag any of:
   - Hardcoded role check instead of `can*` helper (`if (role === 'admin')`, `user?.isAdmin`, `currentUser.permissions.includes(...)`)
   - Permission helper imported from anywhere other than `@daxwell/utils`
   - Field-level gate using the wrong entity name (entity in code != entity in query) — common copy-paste bug
   - Mutation that shows success UI before the permission check resolves (loading state assumed, no `canUpdate` guard)
6. **Group findings.** Bucket by `entity` first, then by `file`, then by `severity` within each file.
7. **Write the report** to `docs/reports/<page-slug>-permission-check.md`. Slug = the entry file's kebab-case name minus `-view`/`-page`/`-details` suffix. Example: `sales-order-details-view.tsx` → `docs/reports/sales-order-permission-check.md`. If a report at that path already exists, append `-NN` (`-02`, `-03`) — never overwrite.
8. **Print the summary in chat.** Counts by severity, top 5 most-impacted files, and the file path of the saved report. Do not paste the full report into chat.

#### Report file structure

The report MUST have this skeleton (mirror it exactly so reports stay diff-able and easy to scan):

````markdown
# Permission Check — <Human Page Name>

- **Date**: YYYY-MM-DD
- **Author**: <git user.name>
- **Status**: Open
- **Scope**: <relative path to the entry file>
- **Re-run command**: `/biz-ui-forge --permission-check <relative path to the entry file>`

## Summary

| Severity | Count |
| --- | --- |
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |
| **Total findings** | **N** |
| OK (verified gated) | N |
| N/A (static / not query-driven) | N |

**Verdict**: BLOCKED | CAUTION | CLEAR

- **BLOCKED** — any CRITICAL finding
- **CAUTION** — no CRITICAL but ≥ 1 HIGH
- **CLEAR** — only MEDIUM/LOW or zero findings

## Files audited

| File | Findings | Top severity |
| --- | --- | --- |
| `apps/scm/src/.../foo.tsx` | 4 | CRITICAL |
| ... | ... | ... |

## Findings

### `apps/scm/src/.../foo.tsx`

#### [CRITICAL] Edit button visible without `canUpdate('Shipment')` gate
- **Line**: 142
- **Element**: `<ActionButton onClick={handleSave}>Edit</ActionButton>`
- **Bound entity / field**: `Shipment` (entity-level mutation)
- **Expected gate**: `canUpdate('Shipment')` via `shouldRender` prop
- **Suggested fix**:
  ```tsx
  import { canUpdate } from '@daxwell/utils';

  <ActionButton shouldRender={canUpdate('Shipment')} onClick={handleSave}>
    Edit
  </ActionButton>
  ```
- **Why this matters**: Users without write permission can click Edit and trigger the update mutation; backend returns 403, UI lands in an unrecoverable state.

#### [HIGH] Field `totalWeight` rendered without `canReadField` gate
- **Line**: 86
- **Element**: `<Typography>{shipment.totalWeight}</Typography>`
- **Bound entity / field**: `Shipment.totalWeight`
- **Expected gate**: `canReadField('Shipment', 'totalWeight')` via conditional render or `shouldRender`
- **Suggested fix**:
  ```tsx
  import { canReadField } from '@daxwell/utils';

  {canReadField('Shipment', 'totalWeight') && (
    <Typography>{shipment.totalWeight}</Typography>
  )}
  ```
- **Why this matters**: Sensitive metric leaks to roles that should not see it.

(...repeat per finding, grouped by file then ordered CRITICAL → HIGH → MEDIUM → LOW within each file...)

## Anti-patterns detected

(One bullet per anti-pattern with file:line and a one-line explanation. Omit the section if none.)

## Verified gates (sample)

A short sample (max 10) of correctly gated elements, so the user can see what "right" looks like in this codebase. Each line: `file:line — element — helper used`.

## Next steps

- [ ] Fix all CRITICAL findings before merge
- [ ] Fix HIGH findings as part of this PR or a follow-up
- [ ] Triage MEDIUM/LOW into a backlog ticket
- [ ] Re-run `/biz-ui-forge --permission-check <path>` and confirm zero CRITICAL/HIGH

## Re-run

```
/biz-ui-forge --permission-check <relative path to the entry file>
```
````

#### Readability rules for the report

- Keep finding bodies short — one paragraph max per finding plus the fix snippet.
- The fix snippet must be valid TypeScript that compiles in this codebase: import the helper from `@daxwell/utils`, use the project's existing `shouldRender` / `colIf` / conditional-render conventions, never introduce a new helper.
- Use tables for summary data (counts, file index). Use bulleted lists or fenced code blocks for findings.
- Use absolute kebab-case file paths relative to repo root. Always include `:line` so the user can jump.
- No emojis, no AI-fluff openers ("It's important to note that..."), no apology language.
- ISO date in `YYYY-MM-DD` for the Date field.
- The Author field comes from `git config user.name` — never blank, never "Claude" / "AI".

#### Scope guards

- This mode **never edits source code**. It only writes `docs/reports/<slug>-permission-check.md`.
- Do not check tests, storybooks, mocks, or fixture files — only production page code under `apps/scm/src/`, `apps/supplier/src/`, and `packages/ui/src/components/` when those components own visible zones for the audited page.
- Do not flag elements rendering hardcoded labels, headings, or static copy — only elements whose value comes from a query, fragment, selector, or cache read.
- Do not propose backend permission changes — only frontend gate placement.
- If the entry file is a list page using AG Grid SSRM, also audit the column definition file (`*-columns.ts(x)`) and the row-action / cell-renderer files.
- If the page renders a modal sourced from a separate file (e.g., `<EntityName>EditModal.tsx`), include the modal in the audit and any input fields it owns.

**Exit checklist:**

- [ ] Entry component resolved to a real file path (not a route guess)
- [ ] Render tree traversed: entry + every child file that renders query-driven UI
- [ ] Every Typography/InfoRow/Chip/Card/Section/colDef/button/icon-button/menu-item/modal-trigger/file-action/editable-input bound to backend data was inspected (not just the parent file)
- [ ] Each finding has: severity, file:line, element snippet, bound entity/field, expected gate, fix snippet importing from `@daxwell/utils`
- [ ] Severity assigned per the table (CRITICAL for unguarded mutations, HIGH for unguarded sensitive reads, MEDIUM/LOW for defense-in-depth)
- [ ] Anti-patterns section populated when present (hardcoded role checks, wrong entity name, helpers imported from anywhere other than `@daxwell/utils`)
- [ ] Report saved at `docs/reports/<page-slug>-permission-check.md` with full skeleton, never overwriting an existing file (suffix `-02`/`-03` if collision)
- [ ] Date in ISO format, Author from `git config user.name`, Status = `Open`
- [ ] Chat summary printed: counts by severity, verdict, top 5 files, saved-report path — no full report in chat
- [ ] No edits to `apps/`, `packages/`, or any `.ts`/`.tsx` source file — only the new markdown report

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
