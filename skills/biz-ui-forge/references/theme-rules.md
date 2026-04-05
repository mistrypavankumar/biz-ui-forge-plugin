# Theme Rules

Apply these rules to all real MUI code:

- use semantic palette tokens such as `text.primary`, `background.paper`, `divider`, `success.main`
- use theme spacing instead of raw pixel spacing when writing MUI code
- use theme typography variants instead of ad hoc font sizing where possible
- use project shadow and radius tokens when available
- before writing any UI code, read `packages/ui/src/theme/theme-config.ts` and `theme-overrides.ts` to confirm available palette tokens — do not assume MUI defaults
- use `theme.palette.<color>.main` for visible text and borders — avoid `.light` or `.lighter` which may not exist or be too faint in this project's palette
- for tinted backgrounds on dark surfaces, use `alpha(theme.palette.<color>.main, 0.16)` as the minimum opacity — never below 0.16
- ensure the UI still works in light and dark mode
- provide hover and focus states for interactive elements
