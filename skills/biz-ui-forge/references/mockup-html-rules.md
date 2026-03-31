# Mockup HTML Output Rules

Reference for `/biz-ui-forge --mockup` mode.

Each mockup is a **single self-contained `.html` file**. Every rule below is mandatory.

---

## Dashboard Shell — Always Include

Every mockup for a dashboard page **must** render the full application shell. This is not optional.

The shell consists of three elements:

| Element | Description |
|---------|-------------|
| **Left sidebar** | Fixed ~220px (`w-56`), `bg-surface-paper`, border-right, logo at top, nav items below |
| **Top header bar** | Fixed height ~56px (`h-14`), `bg-surface-paper`, border-bottom, role selector left · search + avatar right |
| **Main content area** | `flex-1`, right of sidebar, below header, `overflow-y-auto` |

**Nav items to show in sidebar** (from `layouts/nav-config-dashboard.tsx`):
- Home, Products (expandable), Business Objects, Customers, Vendors, Sales, Procurement, Logistics
- Products section must be **expanded** when the page being mocked is under Products
- The active page's nav item gets `text-primary bg-primary/10 font-semibold`; all others get `text-ink-secondary`

**Outer layout skeleton:**
```html
<div class="flex h-screen overflow-hidden">
  <aside class="w-56 flex-shrink-0 flex flex-col bg-surface-paper border-r border-white/10 overflow-y-auto">
    <!-- logo + nav items -->
  </aside>
  <div class="flex-1 flex flex-col min-w-0">
    <header class="flex-shrink-0 h-14 bg-surface-paper border-b border-white/10 flex items-center justify-between px-5">
      <!-- role selector | search + avatar -->
    </header>
    <main class="flex-1 overflow-y-auto overscroll-contain">
      <!-- page content -->
    </main>
  </div>
</div>
```

---

## File Structure Template

```html
<!DOCTYPE html>
<html lang="en" data-concept="<a|b|c>">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Mockup <A|B|C> — <Direction Name> — <UI Name></title>

  <!-- Only allowed external dependency -->
  <script src="https://cdn.tailwindcss.com"></script>

  <!-- Project token extension — always include exactly this block -->
  <script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: { sans: ["system-ui", "-apple-system", "'Segoe UI'", "sans-serif"] },
          colors: {
            primary:  { DEFAULT: "#00A76F", light: "#5BE49B", lighter: "#C8FAD6", dark: "#007867" },
            success:  { DEFAULT: "#22C55E" },
            warning:  { DEFAULT: "#FFAB00" },
            error:    { DEFAULT: "#FF5630" },
            info:     { DEFAULT: "#00B8D9" },
            surface:  { default: "#141A21", paper: "#1C252E", neutral: "#28333D", elevated: "#313D4A" },
            ink:      { primary: "#FFFFFF", secondary: "#919EAB", disabled: "#637381" },
          },
          boxShadow: {
            z1:  "0 1px 2px 0 rgba(0,0,0,0.5)",
            z4:  "0 4px 8px -2px rgba(0,0,0,0.5)",
            z8:  "0 8px 16px -4px rgba(0,0,0,0.4)",
            z16: "0 16px 32px -8px rgba(0,0,0,0.4)",
          },
          borderRadius: { sm: "4px", md: "8px", lg: "12px", xl: "16px" },
        },
      },
    }
  </script>

  <!-- Minimal <style> — only what Tailwind cannot express -->
  <style>
    /* Scrollbar */
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: rgba(145,158,171,0.32); border-radius: 9999px; }
    ::-webkit-scrollbar-thumb:hover { background: #637381; }

    /* Global cursor + focus */
    button, [role="button"], a { cursor: pointer; }
    :focus-visible { outline: 2px solid #00A76F; outline-offset: 2px; }

    /* Keyframes (add only what the mockup uses) */
    @keyframes pulse-dot { 0%,100%{opacity:1} 50%{opacity:0.4} }
    .animate-pulse-dot { animation: pulse-dot 2s infinite; }
  </style>
</head>

<body class="bg-surface-default text-ink-primary font-sans text-sm leading-relaxed antialiased">

  <!-- Concept badge — fixed top-right -->
  <div class="fixed top-3 right-3 z-50 px-3 py-1 rounded-full text-[11px] font-bold
              bg-primary text-white shadow-z8 tracking-wide">
    Concept <A|B|C> · <Direction Name>
  </div>

  <!-- Page shell -->
  <div class="flex flex-col h-screen overflow-hidden">
    <header class="flex-shrink-0 bg-surface-paper border-b border-white/10 shadow-z4">
      <!-- breadcrumb, title, status, actions -->
    </header>

    <div class="flex flex-1 min-h-0">
      <main class="flex-1 overflow-y-auto overscroll-contain p-6 flex flex-col gap-5">
        <!-- cards, sections -->
      </main>

      <!-- Side panel — only for split-pane concepts -->
      <aside class="w-72 flex-shrink-0 border-l border-white/10 bg-surface-paper
                    sticky top-0 h-screen overflow-y-auto overscroll-contain">
        <!-- nav anchors, panels -->
      </aside>
    </div>
  </div>

  <script>
    // Lightweight JS only — scroll triggers, tab switching, accordion
  </script>
</body>
</html>
```

---

## index.html Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Mockups: <UI Name></title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: { extend: {
        colors: {
          surface: { default:"#141A21", paper:"#1C252E" },
          ink:     { primary:"#FFFFFF", secondary:"#919EAB", disabled:"#637381" },
          primary: { DEFAULT:"#00A76F", dark:"#007867" },
        },
        boxShadow: { z8: "0 8px 16px -4px rgba(0,0,0,0.4)" },
      }}
    }
  </script>
  <style>button,a{cursor:pointer;}</style>
</head>
<body class="bg-surface-default text-ink-primary font-sans min-h-screen flex flex-col items-center py-14 px-6 antialiased">

  <h1 class="text-3xl font-extrabold tracking-tight mb-2">Mockups: <UI Name></h1>
  <p class="text-sm text-ink-secondary mb-10">Generated: <YYYY-MM-DD> · <source path or description></p>

  <div class="grid grid-cols-3 gap-5 w-full max-w-3xl">

    <!-- Repeat for A, B, C — use distinct accent colors per concept -->
    <div class="bg-surface-paper rounded-xl border border-white/10 p-6 flex flex-col gap-4
                transition-all duration-200 hover:border-primary hover:shadow-z8 hover:-translate-y-1">
      <span class="w-11 h-11 rounded-xl bg-primary flex items-center justify-center
                   text-xl font-extrabold text-white flex-shrink-0">A</span>
      <h2 class="text-base font-bold"><Direction Name></h2>
      <p class="text-sm text-ink-secondary flex-1"><One-line character tagline></p>
      <a href="./concept-a.html" target="_blank"
         class="inline-flex items-center justify-center gap-2 px-4 py-2 rounded bg-primary
                text-white text-[13px] font-semibold transition-all duration-200 hover:bg-primary-dark">
        Open →
      </a>
    </div>

  </div>

  <footer class="mt-12 text-xs text-ink-disabled text-center">
    Status: concepts ready · build not started
  </footer>
</body>
</html>
```

---

## Styling Rules

### Dependencies
Use **Tailwind CSS CDN only** — `<script src="https://cdn.tailwindcss.com"></script>`. No other CDN links. No Google Fonts. No component libraries.

Use Tailwind utility classes for all layout, spacing, color, typography, shadows, and transitions. Reserve `<style>` only for: scrollbar, keyframe animations, and pseudo-element content.

### Typography

| Role | Tailwind classes |
|------|-----------------|
| Page title | `text-2xl font-extrabold tracking-tight leading-tight` |
| Section label | `text-[11px] font-bold tracking-widest uppercase text-ink-secondary` |
| Card title | `text-sm font-bold tracking-tight` |
| Field label | `text-[11px] font-medium uppercase tracking-wide text-ink-secondary` |
| Field value | `text-[15px] font-bold` |
| Metric value | `text-2xl font-extrabold tracking-tight` |
| Body text | `text-sm leading-relaxed` |
| Meta / timestamp | `text-xs text-ink-disabled` |

### Card Anatomy

```html
<!-- Card shell — always these classes, no variation -->
<div class="bg-surface-paper rounded-lg border border-white/10 shadow-z1 overflow-hidden">

  <!-- Header — always px-5 py-3.5, never deviate -->
  <div class="flex items-center justify-between px-5 py-3.5 border-b border-white/10 gap-4">
    <span class="text-sm font-bold tracking-tight">Title</span>
    <span class="text-xs text-ink-disabled">meta</span>
  </div>

  <!-- Body — always p-5 -->
  <div class="p-5">...</div>
</div>

<!-- Interactive card: add to shell -->
<div class="... cursor-pointer transition-all duration-200 hover:shadow-z8 hover:border-white/20 hover:-translate-y-0.5">
```

### Icon Rules — No Emojis

**Never use emoji as icons.** Use inline SVG from Heroicons or Lucide:

```html
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
  <path stroke-linecap="round" stroke-linejoin="round" d="..." />
</svg>
```

**Icon bubble** (themed background):
```html
<div class="w-9 h-9 rounded-md flex items-center justify-center flex-shrink-0"
     style="background: rgba(0,167,111,0.15); color: #00A76F">
  <svg width="18" height="18" ...>...</svg>
</div>
```
Use `rgba()` inline style only for icon bubble background/color — everywhere else uses Tailwind.

**Common SVG paths:**
```html
<!-- Truck --> <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12" />
<!-- Check --> <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
<!-- Pin --> <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0ZM19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" />
<!-- Document --> <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
<!-- Cube --> <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
<!-- Arrow right --> <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" />
<!-- Chart bars --> <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
<!-- Three dots --> fill="currentColor" → <path d="M12 6.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 12.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 18.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Z" />
```

### Button Variants

```html
<!-- Primary -->
<button class="inline-flex items-center gap-1.5 px-4 py-2 rounded text-[13px] font-semibold
               bg-primary text-white cursor-pointer border border-transparent
               transition-all duration-200 hover:bg-primary-dark hover:shadow-z4 hover:-translate-y-px
               whitespace-nowrap select-none">Label</button>

<!-- Outline -->
<button class="inline-flex items-center gap-1.5 px-4 py-2 rounded text-[13px] font-semibold
               bg-transparent text-ink-secondary cursor-pointer border border-white/20
               transition-all duration-200 hover:text-ink-primary hover:border-white/40 hover:bg-white/[0.04]
               whitespace-nowrap select-none">Label</button>

<!-- Ghost -->
<button class="inline-flex items-center gap-1.5 px-2.5 py-2 rounded text-[13px] font-semibold
               bg-transparent text-ink-secondary cursor-pointer border border-transparent
               transition-all duration-200 hover:text-ink-primary hover:bg-white/[0.06]
               whitespace-nowrap select-none">Label</button>

<!-- Icon-only -->
<button class="w-8 h-8 flex items-center justify-center rounded cursor-pointer
               bg-transparent border border-white/20 text-ink-secondary
               transition-all duration-200 hover:text-ink-primary hover:border-white/40 hover:bg-white/[0.06]">
  <svg .../>
</button>
```

### Status Badge

```html
<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold
             text-warning bg-warning/10">
  <span class="w-1.5 h-1.5 rounded-full bg-current flex-shrink-0"></span>
  In Transit
</span>
<!-- Variants: text-success bg-success/10 | text-error bg-error/10 | text-info bg-info/10 | text-ink-secondary bg-white/10 -->
```

### Layout Patterns

```html
<!-- Page shell (all concepts use this) -->
<div class="flex flex-col h-screen overflow-hidden">
  <header class="flex-shrink-0">...</header>
  <main class="flex-1 overflow-y-auto overscroll-contain">...</main>
</div>

<!-- Sticky side panel — never use calc(100vh - Xpx) -->
<aside class="sticky top-0 h-screen overflow-y-auto overscroll-contain w-72 flex-shrink-0">

<!-- Split pane -->
<div class="grid grid-cols-[1fr_320px] min-h-0">

<!-- KPI cluster -->
<div class="grid grid-cols-4 gap-4">

<!-- Detail field grid -->
<div class="grid grid-cols-3 gap-x-8 gap-y-5">
```

### Section Separators — No `<hr>`

Use `border-b border-white/10` on the preceding element, or alternate surface background bands:

```html
<section class="py-8 bg-surface-default">
<section class="py-8 bg-surface-paper">
<section class="py-8 bg-surface-neutral">
```

### Interactive Element Rules

- Every `<button>` and `<a>` must have `cursor-pointer` — no exceptions
- Every hover state must have `transition-all duration-200` — no instant flashes
- Hover transforms: use `-translate-y-*` only — never `scale-*` (causes layout shift)

### Realistic Data

- Use real-looking IDs: `SHP-2024-08471`, `SO-2024-11293`, `BOL-2024-39847`
- Use real names, addresses, dates, amounts
- Show the most interesting state — partial/in-progress, not empty and not perfect
- All field values must match the data model from the scanned component

### Lightweight JS (Allowed Patterns Only)

```js
// Scroll-triggered floating bar
mainEl.addEventListener('scroll', () => {
  floatingBar.classList.toggle('opacity-0', mainEl.scrollTop < 80);
  floatingBar.classList.toggle('-translate-y-full', mainEl.scrollTop < 80);
});

// Tab switching
document.querySelectorAll('[data-tab]').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('[data-tab]').forEach(t => {
      t.classList.remove('text-primary', 'border-primary');
      t.classList.add('text-ink-secondary', 'border-transparent');
    });
    tab.classList.add('text-primary', 'border-primary');
  });
});

// Accordion
btn.addEventListener('click', () => body.classList.toggle('hidden'));
```

No fake data fetching. No setTimeout loading. No complex state.

---

## Pre-Delivery Checklist

Before writing any file, verify:

**Structure & Tokens**
- [ ] Tailwind CDN script is in `<head>`
- [ ] `tailwind.config` block with all project tokens present
- [ ] No emoji characters used as icons anywhere
- [ ] Concept badge visible in top-right corner of each file
- [ ] `index.html` links to all 3 concepts and opens them in `target="_blank"`

**Layout**
- [ ] All cards: `bg-surface-paper rounded-lg border border-white/10 shadow-z1 overflow-hidden`
- [ ] Card headers: `px-5 py-3.5 border-b border-white/10` — consistent, never mixed
- [ ] Side panel: `sticky top-0 h-screen overflow-y-auto` — not `calc(100vh - ...)`
- [ ] Grid layouts use `grid gap-*` — no individual `mb-*`/`mt-*` on grid children
- [ ] No `<hr>` elements — use `border-b` or surface bands
- [ ] Fixed headers/bars reserve padding so scroll content is not hidden underneath
- [ ] Custom scrollbar CSS present in `<style>`

**Interaction**
- [ ] Every `<button>` and `<a>` has `cursor-pointer`
- [ ] All hover states have `transition-all duration-200`
- [ ] Hover transforms are `-translate-y-*` only — no `scale-*` (causes layout shift)
- [ ] Disabled elements: reduced opacity (`opacity-40` or `opacity-50`) + `cursor-not-allowed`
- [ ] Loading/async buttons show a spinner or disabled state — never just do nothing

**Accessibility**
- [ ] Icon-only buttons have `aria-label` describing the action
- [ ] All form inputs have a visible `<label>` — never placeholder-only
- [ ] `role="alert"` or `aria-live="polite"` on error/success message regions
- [ ] Color is never the sole meaning carrier — pair with icon or text label (e.g. status badges already do this with a dot + text)
- [ ] `:focus-visible` rule present in `<style>` — ensures keyboard navigation is visible
- [ ] Text contrast meets 4.5:1 minimum — `text-ink-primary` on `surface-paper` passes; `text-ink-secondary` on `surface-default` passes; verify any custom combos

**Animation**
- [ ] Micro-interaction durations: 150–300ms — no `duration-500` or higher on hover states
- [ ] Entrance animations (if any): `ease-out`; exit animations: `ease-in`
- [ ] No more than 2 animated moments per mockup concept
