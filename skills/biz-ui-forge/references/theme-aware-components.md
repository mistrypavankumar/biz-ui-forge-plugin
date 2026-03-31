# Theme-Aware Component Rules

Reference for `/biz-ui-forge` — enforced across all modes that produce code (redesign, build, fix, mui-prototype).

## Core Principle

Every component must render correctly in **both light and dark mode** using the project's theme tokens. Never hardcode colors. Never assume one color scheme.

## Theme Discovery

Before writing code, discover the host project's theme:

1. Search for theme config files (`theme-config.*`, `theme.*`, `createTheme`, `extendTheme`)
2. Read palette definitions — extract all available colors with their variants (lighter, light, main, dark, darker)
3. Read typography config — extract custom variants beyond MUI defaults
4. Read shadow/elevation tokens
5. Read spacing/dimension tokens
6. Check if CSS variables mode is enabled and what the prefix is
7. Check if theme overrides exist that replace base palette colors at runtime

## Mandatory Rules

### 1. Use semantic palette tokens, never hex values

```tsx
// CORRECT
sx={{ color: 'text.primary' }}
sx={{ bgcolor: 'background.paper' }}
sx={{ borderColor: 'divider' }}
sx={{ color: 'success.main' }}

// WRONG — breaks in opposite mode
sx={{ color: '#1A252F' }}
sx={{ bgcolor: '#F6F8FC' }}
sx={{ borderColor: '#D7DDE8' }}
```

### 2. Use theme vars for dynamic styles

When building dynamic styles or using alpha overlays:

```tsx
// CORRECT — resolves to CSS variable, works in both modes
sx={{ bgcolor: (theme) => varAlpha(theme.vars.palette.grey['500Channel'], 0.08) }}

// If project doesn't use CSS vars, use theme callbacks
sx={{ bgcolor: (theme) => alpha(theme.palette.grey[500], 0.08) }}
```

### 3. Surface hierarchy must use theme backgrounds

```tsx
sx={{ bgcolor: 'background.default' }}   // Page canvas
sx={{ bgcolor: 'background.paper' }}     // Cards, panels, modals
sx={{ bgcolor: 'background.neutral' }}   // Subtle alternate sections (if available)
```

### 4. Borders and dividers adapt automatically

```tsx
sx={{ borderColor: 'divider' }}
sx={{ border: '1px solid', borderColor: 'divider' }}
```

### 5. Shadows use project shadow tokens

```tsx
// Use whatever shadow system the project defines
sx={{ boxShadow: (theme) => theme.customShadows?.z1 ?? theme.shadows[1] }}
sx={{ boxShadow: (theme) => theme.customShadows?.card ?? theme.shadows[4] }}
```

### 6. Status colors are typically mode-safe

Semantic palette colors (`success`, `warning`, `error`, `info`) are usually identical in both modes:

```tsx
<Chip label="Confirmed" sx={{ bgcolor: 'success.lighter', color: 'success.dark' }} />
```

If the project doesn't define `lighter`/`darker` variants, use alpha:

```tsx
sx={{ bgcolor: (theme) => alpha(theme.palette.success.main, 0.12), color: 'success.main' }}
```

### 7. Typography colors use text tokens

```tsx
<Typography color="text.primary">      // Main text
<Typography color="text.secondary">    // Labels, descriptions
<Typography color="text.disabled">     // Muted, timestamps
```

### 8. Interactive state colors use action tokens

```tsx
sx={{ '&:hover': { bgcolor: 'action.hover' } }}
sx={{ bgcolor: 'action.selected' }}
sx={{ opacity: (theme) => theme.palette.action.disabledOpacity }}
```

### 9. Primary accent uses the project's actual primary

Do not assume primary is blue/green/purple — read the theme to find out:

```tsx
<Button variant="contained" color="primary">
sx={{ bgcolor: 'primary.lighter', color: 'primary.dark' }}
```

### 10. Use project typography variants

If the project defines custom variants (e.g., `pageTitle`, `sectionTitle`), use them:

```tsx
<Typography variant="pageTitle">       // If available
<Typography variant="h4">              // Standard MUI fallback
```

## Dark Mode Verification Checklist

Before finalizing any component:

- [ ] No hardcoded hex colors in `sx`, `style`, or CSS
- [ ] Text is readable against its background in both modes
- [ ] Borders use `divider` token, not grey hex values
- [ ] Backgrounds use `background.*` tokens
- [ ] Status colors use semantic palette (`success`, `warning`, `error`, `info`)
- [ ] Shadows use project shadow tokens
- [ ] Alpha overlays use theme-aware functions (not static hex)
- [ ] Primary accent matches the project's actual primary color
- [ ] `contrastText` is used for text on colored backgrounds
- [ ] Interactive states use `action.*` tokens

## Handling Projects Without Full Theme Setup

If the project has minimal or no theme customization:

1. Use standard MUI palette tokens — they auto-switch with `ThemeProvider` mode
2. Use `theme.palette.mode` to conditionally style if needed
3. Suggest to the user that they set up a theme config for better dark mode support
4. Still avoid hardcoded hex — use MUI's built-in palette tokens at minimum
