# Learned Rules

Rules distilled from repeated corrections. These have the **same weight as non-negotiable rules** in SKILL.md — violating a learned rule is treated as a bug.

Rules are promoted here from `corrections-log.md` when they meet promotion criteria (count >= 2, high severity, or explicit user instruction).

---

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

### LR-003 — Run type-check after every UI change and fix all errors
- **Promoted from**: TS-001 (2026-04-02), user explicit instruction
- **Category**: incomplete-phase
- **Rule**: After creating or modifying any UI component, run `pnpm --filter <pkg> type-check` on the affected package(s) and fix all TypeScript errors before presenting work as complete. Common pitfalls: unused imports, AG Grid `cellStyle` needing `as CellStyle` assertion in array literals, missing type imports.
- **Why**: User had to manually report TS errors that should have been caught before delivery. UI work is not done until it compiles clean.

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
