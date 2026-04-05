# Audit Framework

Reference for `/biz-ui-forge` audit and redesign modes.

---

## What to Read

For the component(s) being audited, read:
1. The component file(s) provided
2. Key imports — especially any child components that affect layout, and any data-fetching hooks
3. Any adjacent `types/` files to understand the data shape

Do not read the entire codebase. Focus on: structure, layout decisions, visual patterns, data presentation, and interaction states.

---

## Audit Report Format

```
## Audit: <ComponentName>

### What Works
- [Preserve these — structurally sound or visually effective]
- ...

### What's Generic
- [Default MUI patterns with no design intent — things that look like boilerplate]
- ...

### What's Dated
- [Layout or interaction patterns that feel stale for 2025+]
- ...

### Hierarchy Problems
- [Typography, spacing, or color decisions that obscure visual priority]
- ...

### Opportunity Areas
- [Specific places where a design decision would create distinction]
- ...
```

---

## Scoring

Rate each dimension 1–5 after the qualitative sections:

| Dimension | 1 | 3 | 5 |
|-----------|---|---|---|
| **Visual Identity** | Indistinguishable from MUI default | Some intentional choices | Clear, ownable aesthetic |
| **Layout Architecture** | No zone hierarchy | Rough zones but inconsistent | Clear header/content/action hierarchy |
| **Interaction Quality** | No hover/focus/loading states | Partial states | Full state coverage (hover, focus, loading, disabled, active) |
| **Data Communication** | Labels and values indistinguishable | Some hierarchy | Clear label/value contrast, semantic color |
| **Consistency** | Patterns differ across sections | Mostly consistent | Single coherent visual language |
| **Accessibility** | No ARIA, poor contrast, no keyboard nav | Partial a11y; some contrast issues | ARIA labels, 4.5:1 contrast, visible focus rings, keyboard-navigable |
| **Forms & Feedback** | Placeholder-only labels, no error states | Some feedback, labels present | Visible labels, inline errors, loading states, success confirmation |

Example output:
```
Scores: Visual Identity 2/5 · Layout Architecture 3/5 · Interaction 1/5 · Data 2/5 · Consistency 3/5 · Accessibility 2/5 · Forms 1/5
```

---

## What "Generic" Looks Like (Checklist)

Use this to identify problems quickly:

**Visual / Layout**
- [ ] `Typography variant="h4"` or `variant="h6"` as page/section title (should use `pageTitle`/`sectionTitle`)
- [ ] `sx={{ fontSize, fontWeight }}` inline on Typography (should use variant)
- [ ] Every card at identical elevation (all `elevation={1}` or no shadow variation)
- [ ] `<Divider />` between every section (surface banding is better)
- [ ] Status displayed as plain text (not color-coded chip or status rail)
- [ ] Action buttons always bottom-right of cards (not floating, not contextual)
- [ ] Breadcrumb + title + buttons all in one flat `Stack` (no header zone separation)
- [ ] Same `body1` size for both field labels and field values
- [ ] Primary color used for every accent element (no semantic color application)

**Interaction / States**
- [ ] No hover states on interactive cards or rows
- [ ] No loading skeleton — content flashes in
- [ ] Empty states = blank space (no ghost CTA)
- [ ] Disabled elements look identical to enabled (no opacity change or cursor shift)
- [ ] Hover transitions instant — no `transition` property
- [ ] No visible focus ring — keyboard users can't navigate

**Accessibility**
- [ ] Icon-only buttons have no `aria-label`
- [ ] Color is the sole meaning carrier (e.g. red/green without icon or text label)
- [ ] Form inputs have no visible `<label>` — placeholder used as label
- [ ] Error messages only at top of form — not inline near the field
- [ ] Interactive elements below 44×44px effective target area
- [ ] Text contrast fails 4.5:1 (common: gray label on paper background)

**Forms & Feedback**
- [ ] No loading indicator on async submit — button just does nothing
- [ ] Error message says "Invalid" with no recovery path
- [ ] No confirmation before destructive actions (delete, cancel, void)

---

## Audit vs. Redesign Distinction

| Mode | Output | Code? |
|------|--------|-------|
| `audit` | Report only — no implementation changes | No |
| `redesign` | Audit → Direction Brief → Architecture → New implementation | Yes — full rewrite |

In `redesign` mode, the audit report is produced first. Do not start the direction brief until the audit is complete. Do not start code until the direction brief is locked.
