#!/usr/bin/env bash
set -uo pipefail

# Stop gate: when the turn tries to end, run `moon check`. If there are errors,
# block the stop and feed the diagnostics back so the turn can't finish dirty.
# This is the hard guarantee (level-triggered); the heartbeat is just awareness.

export PATH="$HOME/.moon/bin:$PATH"

input=$(cat)

# Circuit breaker: if this stop is already the result of a prior block
# (stop_hook_active), don't block again -- otherwise an unfixable error would
# loop forever. One forced fix pass, then allow the stop.
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
if [ "$active" = "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

raw=$(moon check --output-json 2>&1)
errors=$(printf '%s\n' "$raw" | jq -rR 'fromjson? | .level? // empty' \
  | grep -c '^error$' || true)

# Clean -> allow the turn to end.
if [ "$errors" -eq 0 ]; then
  exit 0
fi

# Errors present -> block, with the error list as the reason.
details=$(printf '%s\n' "$raw" \
  | jq -rR 'fromjson? | select(.level? == "error") | "  \(.path // "?"): \(.message // "")"' \
  | head -40)

reason="moon check found ${errors} error(s) -- fix before ending the turn:
${details}"

jq -nc --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
