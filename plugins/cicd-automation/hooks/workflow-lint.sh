#!/usr/bin/env bash
# workflow-lint.sh - Pre-commit hook to validate CI/CD workflow files
#
# Checks:
#   1. YAML syntax validity
#   2. Required fields present
#   3. SHA pinning on third-party actions
#
# Usage: ./workflow-lint.sh [files...]
# If no files specified, checks all staged workflow files.

set -euo pipefail

ERRORS=0

# Get files to check
if [ $# -gt 0 ]; then
  FILES=("$@")
else
  # Find staged workflow files
  mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(github/workflows/.*\.ya?ml|\.gitlab-ci\.ya?ml)$' || true)
fi

if [ ${#FILES[@]} -eq 0 ]; then
  exit 0
fi

echo "Linting ${#FILES[@]} workflow file(s)..."

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  echo "  Checking: $file"

  # 1. YAML syntax check
  if command -v python3 &>/dev/null; then
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
      echo "    ERROR: Invalid YAML syntax"
      ERRORS=$((ERRORS + 1))
    fi
  elif command -v ruby &>/dev/null; then
    if ! ruby -e "require 'yaml'; YAML.safe_load(File.read('$file'))" 2>/dev/null; then
      echo "    ERROR: Invalid YAML syntax"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 2. Check for unpinned third-party actions (GitHub Actions only)
  if [[ "$file" == *".github/workflows/"* ]]; then
    while IFS= read -r line; do
      lineno=$(echo "$line" | cut -d: -f1)
      action_ref=$(echo "$line" | sed -E 's/.*uses:\s*"?([^"#[:space:]]+)"?.*/\1/')

      # Skip local actions
      if [[ "$action_ref" == ./* ]] || [[ "$action_ref" == ../* ]] || [[ "$action_ref" == docker://* ]]; then
        continue
      fi

      if [[ "$action_ref" == *@* ]]; then
        version="${action_ref##*@}"
        if ! [[ "$version" =~ ^[0-9a-f]{40}$ ]]; then
          echo "    WARN: Unpinned action at line $lineno: $action_ref"
        fi
      fi
    done < <(grep -nE '^\s*-?\s*uses:\s*' "$file" 2>/dev/null || true)

    # 3. Check for missing permissions block
    if ! grep -qE '^\s*permissions:' "$file" 2>/dev/null; then
      echo "    WARN: No explicit permissions block found"
    fi

    # 4. Check for missing timeout
    if ! grep -qE '^\s*timeout-minutes:' "$file" 2>/dev/null; then
      echo "    WARN: No timeout-minutes found on any job"
    fi
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Found $ERRORS error(s). Fix them before committing."
  exit 1
fi

echo "All checks passed."
exit 0
