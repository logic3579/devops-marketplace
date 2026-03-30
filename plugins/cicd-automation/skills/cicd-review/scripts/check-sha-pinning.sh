#!/usr/bin/env bash
# check-sha-pinning.sh - Detect unpinned third-party actions in GitHub Actions workflows
#
# Usage: ./check-sha-pinning.sh [path-to-workflows-dir]
# Default path: .github/workflows
#
# Exit codes:
#   0 - All actions are pinned or first-party
#   1 - Unpinned actions found
#   2 - No workflow files found

set -euo pipefail

WORKFLOWS_DIR="${1:-.github/workflows}"
UNPINNED=0
CHECKED=0

# First-party actions that don't need SHA pinning (same repo)
is_local_action() {
  [[ "$1" == ./* ]] || [[ "$1" == ../* ]]
}

# Docker actions (docker://image:tag)
is_docker_action() {
  [[ "$1" == docker://* ]]
}

# Check if a ref looks like a full SHA (40 hex chars)
is_sha_pinned() {
  local ref="$1"
  [[ "$ref" =~ ^[0-9a-f]{40}$ ]]
}

if [ ! -d "$WORKFLOWS_DIR" ]; then
  echo "Error: Workflows directory not found: $WORKFLOWS_DIR"
  exit 2
fi

workflow_files=$(find "$WORKFLOWS_DIR" -name '*.yml' -o -name '*.yaml' 2>/dev/null)

if [ -z "$workflow_files" ]; then
  echo "No workflow files found in $WORKFLOWS_DIR"
  exit 2
fi

echo "Checking SHA pinning in: $WORKFLOWS_DIR"
echo "---"

while IFS= read -r file; do
  # Extract `uses:` references (handles both `- uses:` and `uses:` patterns)
  grep -nE '^\s*-?\s*uses:\s*' "$file" 2>/dev/null | while IFS= read -r line; do
    lineno=$(echo "$line" | cut -d: -f1)
    # Extract the action reference (strip quotes, comments, whitespace)
    action_ref=$(echo "$line" | sed -E 's/.*uses:\s*"?([^"#[:space:]]+)"?.*/\1/')

    CHECKED=$((CHECKED + 1))

    # Skip local and docker actions
    if is_local_action "$action_ref" || is_docker_action "$action_ref"; then
      continue
    fi

    # Split into action and ref (e.g., actions/checkout@abc123)
    if [[ "$action_ref" == *@* ]]; then
      action_name="${action_ref%%@*}"
      action_version="${action_ref##*@}"

      if ! is_sha_pinned "$action_version"; then
        echo "UNPINNED: $file:$lineno"
        echo "  Action: $action_name"
        echo "  Ref:    $action_version (expected full SHA)"
        echo ""
        UNPINNED=$((UNPINNED + 1))
      fi
    else
      echo "UNPINNED: $file:$lineno"
      echo "  Action: $action_ref"
      echo "  Ref:    (none - no @ version specified)"
      echo ""
      UNPINNED=$((UNPINNED + 1))
    fi
  done
done <<< "$workflow_files"

echo "---"
if [ "$UNPINNED" -gt 0 ]; then
  echo "Found $UNPINNED unpinned action(s). Pin all third-party actions to full commit SHAs."
  exit 1
else
  echo "All third-party actions are properly SHA-pinned."
  exit 0
fi
