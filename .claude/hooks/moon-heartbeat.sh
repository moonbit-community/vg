#!/usr/bin/env bash
set -uo pipefail

# PostToolUse heartbeat: after a MoonBit-relevant edit, run `moon check` and
# report the error/warning counts back to the model as non-blocking context.
# Always reports (even "0 error(s), 0 warning(s)") — stateless, no diffing.

# Ensure moon is on PATH even when the hook runs with a minimal environment.
export PATH="$HOME/.moon/bin:$PATH"

# PostToolUse delivers the event as JSON on stdin; pull the edited file path.
file=$(jq -r '.tool_input.file_path // empty')

# Only edits that can change `moon check` results should trigger a check.
# (matcher catches all file-edit tools; this narrows to MoonBit files.)
case "$file" in
  *.mbt | *.mbt.md | */moon.mod | */moon.pkg) ;; # relevant -> run check
  *) exit 0 ;;                                    # anything else -> silent skip
esac

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# moon check --output-json emits one JSON diagnostic per line, each with "level".
levels=$(moon check --output-json 2>&1 | jq -rR 'fromjson? | .level? // empty')
errors=$(printf '%s\n' "$levels" | grep -c '^error$' || true)
warnings=$(printf '%s\n' "$levels" | grep -c '^warning$' || true)

jq -nc --arg ctx "moon check: ${errors} error(s), ${warnings} warning(s)" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
exit 0
