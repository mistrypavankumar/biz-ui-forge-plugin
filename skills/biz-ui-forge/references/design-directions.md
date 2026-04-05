# Design Directions

Reference for `/biz-ui-forge` — loaded during Direction Brief step.

---

## Modern Business UI Directions

Choose based on page purpose and audience. One direction per design — do not blend.

| Direction | Best For | Character |
|-----------|----------|-----------|
| **Command Center** | Dashboards, ops pages | Dark header bar, metric clusters, split-pane, data-first hierarchy |
| **Structured Flow** | Forms, wizards, onboarding | Step progress rail, single-column, generous breathing room |
| **Analyst's Canvas** | Reports, analytics, charts | Wide canvas, dense but ordered, sticky filter controls, filterable grid |
| **Transaction Hub** | PO/SO/shipment detail pages | Left-anchored status rail, card sections, action drawer on right |
| **Smart List** | Browse pages, search results | Sticky command bar, faceted filters, row-level quick actions |
| **Executive Brief** | Summary pages, KPI views | Bold numbers, restrained palette, editorial spacing, minimal chrome |

---

## Unique Differentiators

Every design must include **at least two**. These are what prevent generic output.

| Differentiator | What it is |
|----------------|-----------|
| **Status Rail** | Left/top accent stripe, color-coded per entity state (success/warning/error) |
| **Floating Command Bar** | Action toolbar that detaches from content and sticks on scroll |
| **Metric Cluster** | KPI cards with trend indicators, delta badges, and optional sparklines |
| **Contextual Drawer** | Right-side slide-out for entity details without leaving the list |
| **Staggered Card Grid** | Asymmetric card sizing that creates visual rhythm (not a uniform grid) |
| **Data Density Toggle** | Compact / Comfortable / Spacious view modes stored per user |
| **Section Anchors** | Left-fixed section nav for long detail pages — table-of-contents style |
| **Inline Status Timeline** | Horizontal lifecycle rail inline in the header — shows current stage |
| **Ghost CTA Layer** | Empty-state cards with icon + headline + action that double as onboarding |
| **Layered Surface** | Alternating `background.default` / `background.paper` / `background.neutral` bands — separates sections without borders |

---

## Anti-Patterns

These signal no design intent. Avoid every one.

| Anti-Pattern | The Fix |
|-------------|---------|
| Every section separated by a `<Divider />` | Surface banding or whitespace alone |
| All cards at identical elevation | Vary shadow depth (`z1` / `z8` / `z16`) by hierarchy |
| Page title as `Typography variant="h4"` with inline `sx` | Use `variant="pageTitle"` from the type scale |
| Action buttons clustered bottom-right of every card | Floating command bar or contextual action menus |
| Status shown as plain text | Color-coded chips, status rail, or icon + label |
| Empty state = blank white space | Ghost CTA card: icon + headline + action button |
| Forms with no visual grouping | `sectionTitle` blocks + surface banding between groups |
| Breadcrumb + title + actions all inline in one `Stack` | Header zone: breadcrumb row separate from title+actions row |
| Same text size for labels and values | `caption`/`text.secondary` for labels; `subtitle2`/`body2` for values |
| Primary color on every element | One primary accent per view; use `info`/`success`/`warning` for semantics |
| Identical icon colors for every feature icon | Use semantic or distinct accent colors per category |
| `borderRadius: 0` on all containers | Vary radius: cards `md`, chips `full`, modals `lg` |
