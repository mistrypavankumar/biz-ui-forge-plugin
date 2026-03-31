# Design Directions

Reference for `/biz-ui-forge` direction brief step.

Choose one direction per design. Do not blend directions.

## Modern Business UI Directions

| Direction | Best For | Character |
|-----------|----------|-----------|
| Command Center | Dashboards, ops pages | Dark header bar, metric clusters, split-pane, data-first hierarchy |
| Structured Flow | Forms, wizards, onboarding | Step progress rail, single-column, generous breathing room |
| Analyst's Canvas | Reports, analytics, charts | Wide canvas, dense but ordered, sticky filter controls, filterable grid |
| Transaction Hub | PO, SO, shipment detail pages | Left-anchored status rail, card sections, action drawer on right |
| Smart List | Browse pages, search results | Sticky command bar, faceted filters, row-level quick actions |
| Executive Brief | Summary pages, KPI views | Bold numbers, restrained palette, editorial spacing, minimal chrome |

## Unique Differentiators

Every design must include at least two.

| Differentiator | What it is |
|----------------|------------|
| Status Rail | Left or top accent stripe, color-coded per entity state |
| Floating Command Bar | Action toolbar that detaches from content and sticks on scroll |
| Metric Cluster | KPI cards with trend indicators, delta badges, and optional sparklines |
| Contextual Drawer | Right-side slide-out for entity details without leaving the list |
| Staggered Card Grid | Asymmetric card sizing that creates visual rhythm |
| Data Density Toggle | Compact, comfortable, spacious view modes stored per user |
| Section Anchors | Left-fixed section nav for long detail pages |
| Inline Status Timeline | Horizontal lifecycle rail inline in the header |
| Ghost CTA Layer | Empty-state card with icon, headline, and action |
| Layered Surface | Alternating surface bands instead of divider-heavy sections |

## Anti-Patterns

Avoid these:
- Divider between every section.
- All cards at identical elevation.
- Page title as `Typography variant="h4"` with inline styling.
- Action buttons clustered bottom-right of every card.
- Status shown as plain text.
- Empty state left as blank white space.
- Forms without visual grouping.
- Breadcrumb, title, and actions all inline in one stack.
- Same text size for labels and values.
- Primary color on every element.
- Identical icon colors for every feature icon.
- `borderRadius: 0` on all containers.

## Direction Brief Format

Produce this before code:

```md
Direction: <name>
Unique Differentiators: <at least 2>
Palette Role: primary = <intent> / success-warning-error = <semantics>
Type Hierarchy: pageTitle → sectionTitle → caption + body value pairs
Motion: <up to 2 animated moments>
Memorable Element: <the one thing that makes the page distinctive>
```
