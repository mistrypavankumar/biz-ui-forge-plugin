# biz-ui-forge

A Claude Code plugin for structured business UI design workflows — auditing, redesigning, building, fixing, and prototyping enterprise interfaces with MUI.

## Features

- **7 operating modes**: audit, redesign, build, fix, mockup, mui-prototype, variant
- **Theme-aware**: auto-discovers your project's theme and enforces token usage (no hardcoded colors)
- **Structure matching**: analyzes existing component patterns and mirrors them in new code
- **Dark/light mode**: ensures all output works in both color schemes
- **Production-grade**: outputs React/TypeScript/MUI code that fits your codebase conventions

## Install

### From local path

```bash
# In Claude Code, run:
/plugin install /path/to/biz-ui-forge-plugin
```

```
 # Clone and copy the skill folder
  git clone
  https://github.com/YOUR_USERNAME/biz-ui-forge-plugin.git
  /tmp/biz-ui-forge
  cp -r /tmp/biz-ui-forge/skills/biz-ui-forge
  YOUR_PROJECT/.claude/skills/biz-ui-forge

  Option 3: Git Submodule

  # Inside your project
  git submodule add
  https://github.com/YOUR_USERNAME/biz-ui-forge-plugin.git
  .claude/plugins/biz-ui-forge

  To update later: git submodule update --remote
```

### From GitHub

```bash
# Add your marketplace first (if hosting in a marketplace repo)
/plugin marketplace add your-org/claude-plugins

# Then install
/plugin install biz-ui-forge@your-org-marketplace
```

### Manual (copy into project)

```bash
# Copy the skill directly into your project
cp -r skills/biz-ui-forge /path/to/your-project/.claude/skills/biz-ui-forge
```

## Usage

Once installed, the skill is available as `/biz-ui-forge` in Claude Code.

```
# Audit a component
/biz-ui-forge audit src/components/OrderDetail.tsx

# Build a new page
/biz-ui-forge build a claims management dashboard

# Fix a UI bug
/biz-ui-forge fix the modal header overlaps content on mobile

# Create an HTML mockup
/biz-ui-forge mockup supplier onboarding wizard

# Generate an MUI prototype
/biz-ui-forge mui-prototype inventory transfer form
```

The skill auto-detects the mode from your request. You can also just describe what you want and it will pick the right mode.

## How It Works

1. **Reads your project** — discovers theme files, component patterns, and conventions
2. **Analyzes structure** — extracts the structural blueprint from reference files
3. **Applies design direction** — chooses from 6 business UI design directions
4. **Writes code** — produces theme-aware, structurally consistent output
5. **Verifies** — runs dark mode checklist and structural conformity checks

## Project Theme Discovery

The skill automatically searches for theme files in common locations:

- `src/theme/`, `src/styles/`, `packages/ui/src/theme/`
- Files matching: `theme-config.*`, `palette.*`, `typography.*`, `shadows.*`
- `createTheme` / `extendTheme` calls

It extracts palette colors, typography variants, shadow tokens, and spacing — then enforces their use in all code output.

## References

The skill includes detailed reference documents:

| Reference | Purpose |
|-----------|---------|
| `audit-framework.md` | Scoring dimensions and report format |
| `design-directions.md` | 6 business UI directions with differentiators |
| `mockup-html-rules.md` | Tailwind HTML mockup standards |
| `mui-implementation.md` | MUI layout, color, shadow, motion, and accessibility patterns |
| `mui-prototype-mode.md` | Single-file TSX prototype rules |
| `theme-aware-components.md` | Dark/light mode token rules and verification checklist |
| `structure-match.md` | Structural blueprint extraction and conformity checking |

## License

MIT
