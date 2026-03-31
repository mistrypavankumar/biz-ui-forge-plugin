# Structure Match Reference

Reference for `/biz-ui-forge` build, redesign, and fix modes. Read this to ensure output code follows the host project's structural conventions.

## Purpose

Before writing code, analyze the target file or a similar existing component to extract its structural blueprint. Enforce that same structure on the output so it looks like it belongs in the same codebase.

## Structural Blueprint Extraction

Read the reference file and extract:

### File-Level
- **Directive**: `'use client'` or `'use server'` presence
- **Import order**: group sequence (types → React → UI library → packages → local)
- **Type location**: inline with component, separate `types.ts`, or shared package
- **Type naming**: `ComponentNameProps`, `ActionType`, etc.
- **Component signature**: arrow function, function declaration, or forwardRef
- **Export style**: default or named

### Internal
- **Hook order**: what order are hooks called in (theme → state → refs → memo → effects → custom)
- **State approach**: useState, useRef, Redux, Apollo, React Query, Zustand, or combination
- **Props destructuring**: inline in signature or separate const
- **Sub-components**: inline functions, same-file components, or separate files
- **Memoization**: useMemo/useCallback usage patterns

### UI Patterns
- **Layout primitives**: Stack-based, Grid-based, Box-flex, or mixed
- **Theme token style**: `sx` tokens, styled components, or theme callback
- **Responsive patterns**: breakpoint usage
- **Animation**: Framer Motion, CSS transitions, or none
- **State handling**: how loading/error/empty are rendered

### Folder Conventions
- **File naming**: kebab-case, camelCase, PascalCase
- **Index files**: `index.ts`/`index.tsx` patterns
- **Sub-folders**: `/components/`, `/utils/`, `/types/`, `/hooks/`
- **Config files**: naming patterns

## Blueprint Output Format

Output this before writing code:

```
Reference: <file path>

Structure Blueprint:
  Directive: 'use client' | 'use server' | none
  Imports: [group order observed]
  Types: inline | separate file | shared package
  Signature: arrow function | function declaration | forwardRef
  Export: default | named
  Hooks: [order observed]
  State: [approach observed]
  Layout: Stack-based | Grid-based | Box-flex | mixed
  Sub-components: inline | same-file | separate files
  States: [how loading/error/empty are handled]
  Theme: sx tokens | styled | theme callback
```

## Application Rules

### When creating new components
1. Mirror the reference's file/folder structure exactly
2. Match import organization order
3. Use the same type definition pattern
4. Follow the same component signature style
5. Replicate hook usage order
6. Use identical layout primitive patterns
7. Match state management approach
8. Apply the same loading/error/empty patterns

### When redesigning
1. Preserve the target file's structural conventions
2. Keep import organization, type patterns, hook order
3. Improve UI while maintaining structural consistency
4. If the reference has better patterns, adopt them

### When fixing
1. Read the file's existing patterns first
2. Make the minimal fix following the file's conventions
3. Do not restructure unless the fix requires it
4. Match indentation, naming, and style of surrounding code

## Conformity Checklist

Before delivering, verify:

```
[ ] Directive matches reference
[ ] Import order matches reference grouping
[ ] Type definitions follow same location pattern
[ ] Component signature style matches
[ ] Hook order follows reference convention
[ ] Props destructuring style matches
[ ] Layout primitives match reference choices
[ ] Theme tokens used (no hardcoded colors)
[ ] Loading/error/empty states handled same way
[ ] Export style matches
[ ] File naming convention matches
[ ] Sub-component pattern matches
```
