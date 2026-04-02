#!/bin/bash
# Hook: Detects user correction patterns during biz-ui-forge usage
# Event: UserPromptSubmit
# Behavior: Silently logs raw correction to corrections-log.jsonl AND
#           injects a reminder into Claude's context so it actually logs properly

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Exit early if no prompt
[ -z "$PROMPT" ] && exit 0

# Correction signal patterns (case-insensitive)
# Group 1: Direct corrections
# Group 2: Redo requests
# Group 3: Frustration / repeated mistake signals
PATTERN='(^no[,. !]|not that|wrong |you (forgot|missed|skipped|dropped|ignored)|i (said|asked|told you|meant)|do it again|try again|redo |again[,.]? (you|it|the)|still (wrong|broken|missing|not)|same (mistake|issue|problem|bug)|how many times|i already|stop doing|don.t (do|use|add|hardcode|skip))'

if echo "$PROMPT" | grep -iqE "$PATTERN"; then
  TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
  LOG_DIR="$CWD/.claude/skills/biz-ui-forge"
  LOG_FILE="$LOG_DIR/corrections-log.jsonl"

  # Append raw correction to JSONL (machine-readable, append-only)
  echo "{\"ts\":\"$TIMESTAMP\",\"prompt\":$(echo "$PROMPT" | jq -Rs .)}" >> "$LOG_FILE"

  # Inject reminder into Claude's context
  cat <<'EOF'
[CORRECTION DETECTED] The user appears to be correcting a mistake. Per biz-ui-forge skill protocol:
1. Identify what went wrong in your previous output
2. Log the correction to corrections-log.md with root cause category
3. Check learned-rules.md to see if this is a known pattern
4. Apply the correction and continue
EOF

  exit 0
fi

exit 0
