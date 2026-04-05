# MUI Implementation Patterns

Reference for `/biz-ui-forge` build and redesign modes. Read this before writing any React/TypeScript code.

---

## Layout Primitives

Use these — not custom flex/grid CSS:

```tsx
// Vertical sections
<Stack direction="column" gap={dimensions.gap.section}>

// Horizontal split
<Stack direction="row" gap={dimensions.gap.horizontal}>

// Responsive grid (MUI 7 Grid v2)
<Grid container spacing={3}>
  <Grid size={{ xs: 12, md: 4 }}>

// Full-width surface band
<Box sx={{ bgcolor: 'background.paper', borderBottom: 1, borderColor: 'divider', px: 3, py: 2 }}>
```

---

## Typography

**Always use variants** — never `sx={{ fontSize, fontWeight }}` on Typography.

```tsx
<Typography variant="pageTitle">Shipments</Typography>        // Page identity
<Typography variant="sectionTitle">Overview</Typography>       // Section headers
<Typography variant="caption" color="text.secondary">         // Field labels
<Typography variant="subtitle2" fontWeight="bold">            // Primary data values
<Typography variant="caption" color="text.disabled">          // Timestamps, IDs
```

Custom variants available in this project: `pageTitle`, `sectionTitle`, `modalTitle`.

---

## Color Application

```tsx
// Surface hierarchy
sx={{ bgcolor: 'background.default' }}  // Page canvas
sx={{ bgcolor: 'background.paper' }}    // Cards, panels
sx={{ bgcolor: 'background.neutral' }}  // Subtle alternate sections

// Status — semantic, not decorative
sx={{ color: 'success.main' }}   // Confirmed, complete, secured
sx={{ color: 'warning.main' }}   // Pending, in-progress, draft
sx={{ color: 'error.main' }}     // Cancelled, failed, rejected
sx={{ color: 'info.main' }}      // Informational, neutral in-progress

// Primary — use sparingly (1–2 accents per view)
sx={{ bgcolor: 'primary.main', color: 'primary.contrastText' }}
sx={{ bgcolor: 'primary.lighter', color: 'primary.dark' }}  // Icon bubble
```

---

## Shadows & Depth

```tsx
sx={{ boxShadow: (theme) => theme.customShadows.z1 }}    // Ambient (most cards)
sx={{ boxShadow: (theme) => theme.customShadows.z8 }}    // Interactive / hover elevation
sx={{ boxShadow: (theme) => theme.customShadows.z16 }}   // Floating bars, sticky headers
sx={{ boxShadow: (theme) => theme.customShadows.card }}  // Standard card preset
sx={{ boxShadow: (theme) => theme.customShadows.dialog }}// Modals, drawers
```

---

## Frosted Glass

For contextual panels, overlays, sticky headers:

```tsx
sx={{
  ...theme.mixins.bgBlur({ color: theme.vars.palette.background.paper }),
  backdropFilter: 'blur(8px)',
  border: '1px solid',
  borderColor: 'divider',
}}
```

---

## Motion

```tsx
import { m } from 'framer-motion';
import { varFade } from '@/components/animate';
import { MotionContainer } from '@/components/animate';

// Wrap animated sections
<MotionContainer>
  <m.div variants={varFade().inUp}>

// Staggered card list
<m.div variants={varFade().inRight} transition={{ delay: index * 0.05 }}>

// Panel slide-in (drawer/side panel)
<m.div
  initial={{ x: '100%', opacity: 0 }}
  animate={{ x: 0, opacity: 1 }}
  exit={{ x: '100%', opacity: 0 }}
  transition={{ type: 'spring', damping: 25, stiffness: 300 }}
>
```

Keep motion minimal — 2 animated moments maximum per view. Entrance + one interactive transition.

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
    boxShadow: (theme) => theme.customShadows.z8,
    display: 'flex',
    alignItems: 'center',
    gap: 2,
  }}
>
  <Typography variant="sectionTitle" sx={{ flexGrow: 1 }}>{title}</Typography>
  <Button variant="contained" size="small">{primaryAction}</Button>
  <IconButton size="small"><Iconify icon="eva:more-vertical-fill" /></IconButton>
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
<Card sx={{ p: 3, boxShadow: (theme) => theme.customShadows.card }}>
  <Stack direction="row" alignItems="flex-start" justifyContent="space-between">
    <Box>
      <Typography variant="caption" color="text.secondary" gutterBottom>
        {label}
      </Typography>
      <Typography variant="h4" fontWeight="bold">{value}</Typography>
      <Stack direction="row" alignItems="center" gap={0.5} mt={0.5}>
        <Iconify
          icon={delta > 0 ? 'eva:trending-up-fill' : 'eva:trending-down-fill'}
          sx={{ color: delta > 0 ? 'success.main' : 'error.main', width: 16, height: 16 }}
        />
        <Typography variant="caption" color={delta > 0 ? 'success.main' : 'error.main'}>
          {Math.abs(delta)}% vs last period
        </Typography>
      </Stack>
    </Box>
    <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: 'primary.lighter', color: 'primary.main' }}>
      <Iconify icon={icon} width={24} />
    </Box>
  </Stack>
</Card>
```

### Layered Surface Banding

Separates sections visually without borders:

```tsx
<Box sx={{ bgcolor: 'background.default', py: 4 }}><SectionA /></Box>
<Box sx={{ bgcolor: 'background.paper', py: 4 }}><SectionB /></Box>
<Box sx={{ bgcolor: 'background.neutral', py: 4 }}><SectionC /></Box>
```

### Section Anchor Navigation

For long detail pages — left-rail sticky nav:

```tsx
<Stack
  component="nav"
  sx={{ position: 'sticky', top: 80, width: 200, flexShrink: 0, gap: 0.5 }}
>
  {sections.map((section) => (
    <Button
      key={section.id}
      variant="text"
      size="small"
      href={`#${section.id}`}
      sx={{
        justifyContent: 'flex-start',
        color: activeSection === section.id ? 'primary.main' : 'text.secondary',
        bgcolor: activeSection === section.id ? 'primary.lighter' : 'transparent',
        fontWeight: activeSection === section.id ? 700 : 400,
      }}
    >
      {section.label}
    </Button>
  ))}
</Stack>
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
  <Iconify icon={emptyIcon} width={48} sx={{ color: 'text.disabled', mb: 2 }} />
  <Typography variant="sectionTitle" gutterBottom>{emptyHeadline}</Typography>
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
| Hover | Elevation change (`z1` → `z8`) + subtle border lightening |
| Focus | MUI focus ring — ensure `4.5:1` contrast against background |
| Active / Selected | `primary.lighter` background + `primary.main` text + `700` fontWeight |
| Disabled | `opacity: 0.48` + `cursor: 'not-allowed'` + semantic `disabled` prop |

---

## Accessibility Patterns

### Icon-only buttons

Always include `aria-label`:

```tsx
<IconButton aria-label="More options" size="small">
  <Iconify icon="eva:more-vertical-fill" />
</IconButton>
```

### Semantic color — never color alone

Status chips must always include icon or text label alongside color:

```tsx
// CORRECT — color + dot + text
<Chip
  label="In Progress"
  icon={<Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: 'warning.main' }} />}
  sx={{ color: 'warning.main', bgcolor: 'warning.lighter' }}
/>

// WRONG — color-only signal
<Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: 'warning.main' }} />
```

### Form labels — never placeholder-only

```tsx
// CORRECT
<TextField
  label="Purchase Order Number"
  placeholder="PO-2024-00001"
  helperText="Enter the vendor's PO reference"
/>

// WRONG — label replaced by placeholder
<TextField placeholder="Purchase Order Number" />
```

### Alert regions for async feedback

```tsx
<Box role="alert" aria-live="polite">
  {errorMessage && (
    <Alert severity="error" action={<Button onClick={retry}>Retry</Button>}>
      {errorMessage}
    </Alert>
  )}
</Box>
```

---

## Animation Timing Standards

Follow these timing rules — no exceptions:

| Interaction | Duration | Easing |
|-------------|----------|--------|
| Micro-interaction (hover, focus ring) | 150ms | `ease-out` |
| Component enter | 200ms | `ease-out` |
| Component exit | 150ms | `ease-in` |
| Panel slide-in (drawer, side panel) | 250ms | `spring(damping 25, stiffness 300)` |
| Complex transition (page section) | 300ms | `ease-out` |
| Max allowed | 400ms | — |

```tsx
// MUI transition shorthand
sx={{ transition: (theme) => theme.transitions.create(['box-shadow', 'border-color'], {
  duration: theme.transitions.duration.shorter,  // 200ms
}) }}

// Framer Motion — exit faster than enter
<m.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -4 }}
  transition={{ duration: 0.2, ease: 'easeOut' }}
>
```

Max 2 animated moments per view — entrance + one interactive transition.

---

## Form & Feedback Patterns

### Async submit button

```tsx
<Button
  type="submit"
  variant="contained"
  disabled={isSubmitting}
  startIcon={isSubmitting ? <CircularProgress size={16} color="inherit" /> : undefined}
>
  {isSubmitting ? 'Saving…' : 'Save Changes'}
</Button>
```

### Inline field error

```tsx
<TextField
  label="Quantity"
  error={!!errors.quantity}
  helperText={errors.quantity?.message ?? 'Units in the shipment'}
/>
```

### Destructive confirmation

Never fire destructive actions on first click — always confirm:

```tsx
<Dialog open={confirmOpen}>
  <DialogTitle>Cancel this order?</DialogTitle>
  <DialogContent>
    <DialogContentText>
      This will cancel PO-2024-08471 and notify the supplier. This cannot be undone.
    </DialogContentText>
  </DialogContent>
  <DialogActions>
    <Button onClick={() => setConfirmOpen(false)}>Keep Order</Button>
    <Button onClick={handleCancel} color="error" variant="contained">Cancel Order</Button>
  </DialogActions>
</Dialog>
```

### Error with recovery

```tsx
// Never hide a section on error — show inline with retry
<Alert
  severity="error"
  action={
    <Button size="small" onClick={refetch}>
      Retry
    </Button>
  }
>
  Failed to load shipment details. Check your connection and try again.
</Alert>
```

### Auto-focus first invalid field on submit

```tsx
const onSubmit = handleSubmit((data) => { ... }, (errors) => {
  const firstError = Object.keys(errors)[0];
  setFocus(firstError as FieldPath<FormValues>);
});
```
