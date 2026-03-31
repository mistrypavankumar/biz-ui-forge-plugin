# Audit Framework

Reference for `/biz-ui-forge` audit and redesign modes.

## What to Read

For the component or components being audited, read:
1. The component file or files provided.
2. Key imports, especially child components that affect layout and any data-fetching hooks.
3. Adjacent `types/` files to understand the data shape.

Do not read the entire codebase. Focus on structure, layout decisions, visual patterns, data presentation, and interaction states.

## Audit Report Format

```md
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

## Scoring

Rate each dimension 1–5 after the qualitative sections:

| Dimension | 1 | 3 | 5 |
|-----------|---|---|---|
| Visual Identity | Indistinguishable from MUI default | Some intentional choices | Clear, ownable aesthetic |
| Layout Architecture | No zone hierarchy | Rough zones but inconsistent | Clear header/content/action hierarchy |
| Interaction Quality | No hover or focus or loading states | Partial states | Full state coverage |
| Data Communication | Labels and values indistinguishable | Some hierarchy | Clear label and value contrast, semantic color |
| Consistency | Patterns differ across sections | Mostly consistent | Single coherent visual language |
| Accessibility | No ARIA, poor contrast, no keyboard nav | Partial accessibility | ARIA labels, visible focus rings, keyboard navigable |
| Forms and Feedback | Placeholder-only labels, no error states | Some feedback | Visible labels, inline errors, loading states, success confirmation |

Use this score line format:

```md
Scores: Visual Identity 2/5 · Layout Architecture 3/5 · Interaction 1/5 · Data 2/5 · Consistency 3/5 · Accessibility 2/5 · Forms 1/5
```

## What Generic Looks Like

### Visual and Layout
- `Typography variant="h4"` or `variant="h6"` as page or section title instead of project-specific variants.
- Inline `sx={{ fontSize, fontWeight }}` on Typography instead of a semantic variant.
- Every card at identical elevation.
- Divider between every section.
- Status displayed as plain text.
- Action buttons always bottom-right of cards.
- Breadcrumb, title, and actions all in one flat stack.
- Same text size for labels and values.
- Primary color used for every accent element.

### Interaction and States
- No hover states on interactive cards or rows.
- No loading skeleton.
- Empty state is blank space.
- Disabled elements look identical to enabled ones.
- No transition property.
- No visible focus ring.

### Accessibility
- Icon-only buttons lack `aria-label`.
- Color is the sole meaning carrier.
- Inputs have no visible label.
- Error messages only appear at the top of a form.
- Interactive targets are too small.
- Text contrast is too weak against the background.

### Forms and Feedback
- No loading indicator on async submit.
- Errors are vague and offer no recovery path.
- No confirmation before destructive actions.

## Audit vs Redesign

| Mode | Output | Code |
|------|--------|------|
| audit | report only | no |
| redesign | audit, then direction brief, architecture, and new implementation | yes |

In redesign mode, finish the audit first. Do not jump into direction or implementation before the audit is complete.
