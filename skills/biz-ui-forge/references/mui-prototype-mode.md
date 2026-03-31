# MUI Prototype Mode

Reference for `/biz-ui-forge` when the user wants mockup speed but real MUI structure.

## Purpose

Use this mode when the user says the mockup should be closer to production, should use MUI, or should be easy to paste into a Next.js codebase without a full implementation pass.

This mode is intentionally distinct from HTML mockup mode.
- HTML mockup mode is for instant browser preview with no app dependencies.
- MUI prototype mode is for a single TSX file that feels like real application code.

## Default Deliverable

Produce one self-contained `.tsx` file.

Keep these in the same file by default:
- mock data
- local section config
- small helper renderers
- lightweight local state
- small dialog, drawer, or empty-state helpers

Do not split files unless the user explicitly asks for a production extraction.

## Dependency Policy

Prefer only dependencies already common in the host app:
- `react`
- `@mui/material`
- existing project theme tokens
- existing in-project icon wrapper, if present

Avoid adding new packages.

For icons:
1. Prefer the project's existing icon wrapper.
2. Otherwise use inline SVG.
3. Use `@mui/icons-material` only when the codebase already uses it.

Do not introduce motion, charts, or utility libraries unless they are already present and materially needed for the prototype.

## Structural Expectations

The file should still look like production-oriented React code:
- typed props or typed mock data
- semantic sections
- MUI layout primitives
- theme tokens for spacing, colors, shadows, and radii
- proper states for loading, empty, error, hover, focus, and disabled when relevant

## Single-File Pattern

A strong default shape is:

```tsx
import * as React from 'react';
import { Box, Stack, Card, Typography, Button } from '@mui/material';

const MOCK = { ... };

function MetricCard() {
  return (...);
}

export default function ShipmentPrototype() {
  const [open, setOpen] = React.useState(false);

  return (
    <Box>
      ...
    </Box>
  );
}
```

## Review Standard

The prototype must answer yes to all of these:
- Can the user paste this into a Next.js or React MUI app with minimal edits?
- Does it avoid project-wide dependency churn?
- Is it clearly more production-shaped than an HTML-only mockup?
- Is it still compact enough for fast iteration?

## When to Escalate Beyond Prototype

Switch from MUI prototype mode to full redesign or build mode when:
- real data wiring is required
- the component must be production-ready
- multiple reusable subcomponents are clearly needed
- route integration, server actions, or app-level state boundaries matter
