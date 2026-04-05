# Mockup Playbook

Use this when generating concepts from requirements.

## Role

Act like a senior UI/UX designer for a serious product team.

## Expectations

- Design for workflow clarity, not decoration alone.
- Make layout decisions intentionally: dense, balanced, or spacious.
- Create a memorable but production-plausible concept.
- Avoid generic MUI-looking card grids unless that is truly the best interaction model.

## Mockup quality bar

Every mockup should show:
- clear page purpose in the first screenful
- strong hierarchy between title, filters, primary metrics, and detailed content
- meaningful action placement
- visible empty, selection, or status affordances where relevant
- coherent spacing rhythm

## Hard rules

1. **Pure CSS + icon CDNs only.** No Tailwind, Bootstrap, or any CSS framework CDN. Allowed external dependencies are icon CDNs only (e.g., `@phosphor-icons/web`, Heroicons, Lucide, Remix Icon, Tabler Icons). Pick the best-fitting icon from any family — do not default to Phosphor for everything. Use CSS variables that mirror MUI tokens (`var(--primary-main)` → `'primary.main'`) so implementation mapping is 1:1.

2. **Global style guide is the source of truth.** Read `docs/design/global-style-guide.md` before every mockup. All values (font sizes, radii, shadows, button shapes, spacing) must come from that file. Key corrections vs common defaults: `--radius-sm: 6px` (not 8), `--radius-md: 10px` (not 12), `--radius-lg: 14px` (not 16), buttons use `7px 14px` padding with `10px` radius.

3. **Every concept must be unique.** Never read or reference prior concepts in the same mockup directory. Start fresh from the component source code and global style guide each time. This ensures real design alternatives, not iterations of the same layout.

## Deliverable

Produce a self-contained HTML mockup with pure HTML, CSS, and JS (plus icon CDNs as needed).
