#!/bin/bash
# Hook: Reminds Claude to update all 9 dependent files when nav-config-floating.tsx is edited
# Event: PostToolUse (Edit/Write)
# Behavior: Checks if the tool modified nav-config-floating.tsx and injects the LR-013 checklist

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only trigger on Edit or Write tools
case "$TOOL" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

# Only trigger if the edited file is nav-config-floating.tsx
case "$FILE_PATH" in
  *nav-config-floating.tsx) ;;
  *) exit 0 ;;
esac

cat <<'EOF'
[NAV ROUTE CHECKLIST — LR-013] You just edited nav-config-floating.tsx. If you added, modified, or REMOVED a route, update ALL 9 files:

ADDING a route:
1. packages/constants/src/paths.ts — add route path
2. apps/scm/src/app/dashboard/<route>/page.tsx — create Next.js page
3. apps/scm/src/sections/<route>/index.ts — barrel export
4. apps/scm/src/sections/<route>/view/<name>-list-view.tsx — list view component
5. packages/constants/src/mapping/path-permission-map.ts — add permissions with ACTUAL entity refs (readOnly/curd), NOT empty arrays
6. packages/utils/src/permission-checks/get-permissions-for-path.ts — add regex route matcher to ROUTES array
7. packages/types/src/permission-entity/index.ts AND apps/scm/src/types/permission-entity.ts — add entity to PermissionEntity type
8. apps/scm/src/utils/entity-route-mapping.ts — add NAV_ENTITY_ROUTES entry
9. apps/scm/src/layouts/nav-config-floating.tsx — add nav item (already done)

REMOVING a route — clean up the SAME 9 files in reverse:
1. Remove nav item from nav-config-floating.tsx (already done)
2. Remove NAV_ENTITY_ROUTES entry from entity-route-mapping.ts
3. Remove entity from PermissionEntity types (ONLY if no other route uses it)
4. Remove regex matcher from get-permissions-for-path.ts
5. Remove entry from path-permission-map.ts
6. Delete page.tsx, index.ts, list-view.tsx, and section folder
7. Remove path from paths.ts

Missing any file causes: navigation failures, permission blocks, stale routes, or orphaned code.
EOF

exit 0
