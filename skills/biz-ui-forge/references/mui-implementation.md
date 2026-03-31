# MUI Implementation Patterns

Reference for `/biz-ui-forge` build and redesign modes. Read this before writing any React/TypeScript code.

---

## Layout Primitives

Use these — not custom flex/grid CSS:

```tsx
// Vertical sections
<Stack direction="column" gap={3}>

// Horizontal split
<Stack direction="row" gap={2}>

// Responsive grid (MUI Grid v2)
<Grid container spacing={3}>
  <Grid size={{ xs: 12, md: 4 }}>

// Full-width surface band
<Box sx={{ bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', px: 3, py: 2 }}>
```

---

## Typography

**Always use variants** — never `sx={{ fontSize, fontWeight }}` on Typography.

```tsx
<Typography variant="h4">Page Title</Typography>           // Page identity
<Typography variant="h6">Section Header</Typography>       // Section headers
<Typography variant="caption" color="text.secondary">      // Field labels
<Typography variant="subtitle2" fontWeight="bold">         // Primary data values
<Typography variant="caption" color="text.disabled">       // Timestamps, IDs
```

If the project defines custom variants (e.g., `pageTitle`, `sectionTitle`, `modalTitle`), prefer those over standard MUI variants.

---

## Color Application

```tsx
// Surface hierarchy
sx={{ bgcolor: 'background.default' }}  // Page canvas
sx={{ bgcolor: 'background.paper' }}    // Cards, panels
sx={{ bgcolor: 'background.neutral' }}  // Subtle alternate sections (if available)

// Status — semantic, not decorative
sx={{ color: 'success.main' }}   // Confirmed, complete, secured
sx={{ color: 'warning.main' }}   // Pending, in-progress, draft
sx={{ color: 'error.main' }}     // Cancelled, failed, rejected
sx={{ color: 'info.main' }}      // Informational, neutral in-progress

// Primary — use sparingly (1-2 accents per view)
sx={{ bgcolor: 'primary.main', color: 'primary.contrastText' }}
sx={{ bgcolor: 'primary.lighter', color: 'primary.dark' }}  // Icon bubble (if lighter variant exists)
```

---

## Shadows & Depth

```tsx
// If the project defines custom shadows:
sx={{ boxShadow: (theme) => theme.customShadows?.z1 }}    // Ambient (most cards)
sx={{ boxShadow: (theme) => theme.customShadows?.z8 }}    // Interactive / hover elevation
sx={{ boxShadow: (theme) => theme.customShadows?.card }}   // Standard card preset
sx={{ boxShadow: (theme) => theme.customShadows?.dialog }} // Modals, drawers

// Standard MUI shadows fallback:
sx={{ boxShadow: 1 }}   // Subtle
sx={{ boxShadow: 4 }}   // Cards
sx={{ boxShadow: 8 }}   // Elevated
sx={{ boxShadow: 16 }}  // Modals
```

---

## Frosted Glass

For contextual panels, overlays, sticky headers (if project supports `bgBlur` mixin):

```tsx
sx={{
  ...(theme.mixins.bgBlur
    ? theme.mixins.bgBlur({ color: theme.vars?.palette?.background?.paper ?? theme.palette.background.paper })
    : { bgcolor: 'background.paper' }),
  backdropFilter: 'blur(8px)',
  border: '1px solid',
  borderColor: 'divider',
}}
```

---

## Motion

```tsx
import { m } from 'framer-motion';

// Staggered card list (if Framer Motion is in the project)
<m.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2, ease: 'easeOut', delay: index * 0.05 }}
>

// Panel slide-in (drawer/side panel)
<m.div
  initial={{ x: '100%', opacity: 0 }}
  animate={{ x: 0, opacity: 1 }}
  exit={{ x: '100%', opacity: 0 }}
  transition={{ type: 'spring', damping: 25, stiffness: 300 }}
>
```

If the project has animation utilities (e.g., `varFade`, `MotionContainer`), prefer those. Keep motion minimal — 2 animated moments maximum per view.

---

## Pattern Library

### Floating Command Bar (Sticky Header)

```tsx
<Box
  sx={{
    position: 'sticky',
    top: 0,
    zIndex: 10,
    px: 3,
    py: 1.5,
    bgcolor: 'background.paper',
    borderBottom: 1,
    borderColor: 'divider',
    boxShadow: (theme) => theme.customShadows?.z8 ?? theme.shadows[8],
    display: 'flex',
    alignItems: 'center',
    gap: 2,
  }}
>
  <Typography variant="h6" sx={{ flexGrow: 1 }}>{title}</Typography>
  <Button variant="contained" size="small">{primaryAction}</Button>
  <IconButton size="small" aria-label="More options">...</IconButton>
</Box>
```

### Status Rail

Left accent bar, color changes with entity status:

```tsx
<Box
  sx={{
    position: 'relative',
    pl: 2,
    '&::before': {
      content: '""',
      position: 'absolute',
      left: 0,
      top: 0,
      bottom: 0,
      width: 3,
      bgcolor: statusColor,  // 'success.main' | 'warning.main' | 'error.main'
      borderRadius: 4,
    },
  }}
>
```

### Metric Cluster Card

```tsx
<Card sx={{ p: 3, boxShadow: (theme) => theme.customShadows?.card ?? theme.shadows[4] }}>
  <Stack direction="row" alignItems="flex-start" justifyContent="space-between">
    <Box>
      <Typography variant="caption" color="text.secondary" gutterBottom>
        {label}
      </Typography>
      <Typography variant="h4" fontWeight="bold">{value}</Typography>
      <Stack direction="row" alignItems="center" gap={0.5} mt={0.5}>
        <Typography variant="caption" color={delta > 0 ? 'success.main' : 'error.main'}>
          {Math.abs(delta)}% vs last period
        </Typography>
      </Stack>
    </Box>
    <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: 'primary.lighter', color: 'primary.main' }}>
      {/* icon */}
    </Box>
  </Stack>
</Card>
```

### Layered Surface Banding

Separates sections visually without borders:

```tsx
<Box sx={{ bgcolor: 'background.default', py: 4 }}><SectionA /></Box>
<Box sx={{ bgcolor: 'background.paper', py: 4 }}><SectionB /></Box>
```

### Ghost CTA (Empty State)

```tsx
<Card
  sx={{
    p: 4,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    textAlign: 'center',
    border: '1px dashed',
    borderColor: 'divider',
    bgcolor: 'transparent',
  }}
>
  <Typography variant="h6" gutterBottom>{emptyHeadline}</Typography>
  <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>{emptySubtext}</Typography>
  <Button variant="contained" size="small">{emptyAction}</Button>
</Card>
```

---

## Required States

Every component must handle:

| State | Implementation |
|-------|---------------|
| Loading | `<Skeleton>` — match the shape of the loaded content |
| Empty | Ghost CTA card — icon + headline + action button |
| Error | Inline alert with retry action — never just hide the section |
| Hover | Elevation change + subtle border lightening |
| Focus | MUI focus ring — ensure `4.5:1` contrast against background |
| Active / Selected | `primary.lighter` background + `primary.main` text + bold fontWeight |
| Disabled | `opacity: 0.48` + `cursor: 'not-allowed'` + semantic `disabled` prop |

---

## Accessibility Patterns

### Icon-only buttons — always include `aria-label`

```tsx
<IconButton aria-label="More options" size="small">...</IconButton>
```

### Semantic color — never color alone

Status chips must always include icon or text label alongside color.

### Form labels — never placeholder-only

```tsx
<TextField label="Purchase Order Number" placeholder="PO-2024-00001" />
```

### Alert regions for async feedback

```tsx
<Box role="alert" aria-live="polite">
  {errorMessage && <Alert severity="error" action={<Button onClick={retry}>Retry</Button>}>{errorMessage}</Alert>}
</Box>
```

---

## Animation Timing Standards

| Interaction | Duration | Easing |
|-------------|----------|--------|
| Micro-interaction (hover, focus ring) | 150ms | `ease-out` |
| Component enter | 200ms | `ease-out` |
| Component exit | 150ms | `ease-in` |
| Panel slide-in | 250ms | `spring(damping 25, stiffness 300)` |
| Complex transition | 300ms | `ease-out` |
| Max allowed | 400ms | — |

Max 2 animated moments per view — entrance + one interactive transition.

---

## Form & Feedback Patterns

### Async submit button

```tsx
<Button type="submit" variant="contained" disabled={isSubmitting}
  startIcon={isSubmitting ? <CircularProgress size={16} color="inherit" /> : undefined}>
  {isSubmitting ? 'Saving...' : 'Save Changes'}
</Button>
```

### Destructive confirmation — always confirm before firing

```tsx
<Dialog open={confirmOpen}>
  <DialogTitle>Cancel this order?</DialogTitle>
  <DialogContent>
    <DialogContentText>This cannot be undone.</DialogContentText>
  </DialogContent>
  <DialogActions>
    <Button onClick={() => setConfirmOpen(false)}>Keep</Button>
    <Button onClick={handleCancel} color="error" variant="contained">Cancel Order</Button>
  </DialogActions>
</Dialog>
```

### Auto-focus first invalid field on submit

```tsx
const onSubmit = handleSubmit((data) => { ... }, (errors) => {
  const firstError = Object.keys(errors)[0];
  setFocus(firstError);
});
```
