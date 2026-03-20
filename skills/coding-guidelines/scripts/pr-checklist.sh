#!/usr/bin/env bash
# pr-checklist.sh - Generate a focused PR review checklist based on changed files
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: pr-checklist.sh [-h] [--staged] [BASE_BRANCH]

Generates a markdown review checklist based on files changed in the current
branch compared to a base branch (or staged changes).

Arguments:
  BASE_BRANCH   Branch to diff against (default: auto-detect staging > development > main)

Options:
  --staged      Check staged changes instead of branch diff
  -h, --help    Show this help message

Output: markdown checklist with review items from relevant guidelines.
HELP
  exit 0
}

# Detect base branch: find nearest parent branch, fallback to staging > development > main
detect_base_branch() {
  local current
  current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # Try to find the parent branch via decorated ancestor commits
  if [[ -n "$current" && "$current" != "HEAD" ]]; then
    local parent
    # Walk decorated ancestors, extract remote branch names, skip current branch
    parent=$(git log --decorate --simplify-by-decoration --oneline --format='%D' \
      | grep -oE 'origin/[^ ,]+' \
      | sed 's|origin/||' \
      | grep -v "^${current}$" \
      | grep -v '^HEAD$' \
      | head -1 2>/dev/null || true)
    if [[ -n "$parent" ]]; then
      echo "$parent"
      return
    fi
  fi

  # Fallback: first existing of staging > development > main
  for branch in staging development main; do
    if git rev-parse --verify "$branch" &>/dev/null; then
      echo "$branch"
      return
    elif git rev-parse --verify "origin/$branch" &>/dev/null; then
      echo "origin/$branch"
      return
    fi
  done
  echo "main"
}

STAGED=false
BASE_BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --staged) STAGED=true; shift ;;
    *) BASE_BRANCH="$1"; shift ;;
  esac
done

# Use provided branch or auto-detect
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH=$(detect_base_branch)
fi

# Get changed files
if [[ "$STAGED" == "true" ]]; then
  CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
  DIFF_CONTENT=$(git diff --cached 2>/dev/null || echo "")
else
  CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || echo "")
  DIFF_CONTENT=$(git diff "$BASE_BRANCH"...HEAD 2>/dev/null || echo "")
fi

if [[ -z "$CHANGED_FILES" ]]; then
  echo "No changed files detected."
  exit 0
fi

# Categorize files
has_js=false
has_ts=false
has_jsx=false
has_tsx=false
has_css=false
has_scss=false
has_test=false
has_tailwind=false
has_mantine=false
has_graphql=false

while IFS= read -r file; do
  case "$file" in
    *.js)    has_js=true ;;
    *.ts)    has_ts=true ;;
    *.jsx)   has_js=true; has_jsx=true ;;
    *.tsx)   has_ts=true; has_tsx=true ;;
    *.css)   has_css=true ;;
    *.scss)  has_scss=true; has_css=true ;;
    *.test.*|*.spec.*|*__tests__*) has_test=true ;;
  esac
done <<< "$CHANGED_FILES"

# Check diff content for Tailwind patterns in JSX/TSX
jsx_tsx_files=$(echo "$CHANGED_FILES" | grep -E '\.(jsx|tsx)$' || true)
if [[ -n "$jsx_tsx_files" ]]; then
  tw_pattern='(flex|grid|p-|px-|py-|m-|mx-|my-|bg-|text-|border-|rounded|shadow|w-|h-|(sm|md|lg|hover|focus|dark):)'
  if echo "$DIFF_CONTENT" | grep -qE "$tw_pattern"; then
    has_tailwind=true
  fi
fi

# Check for Mantine imports
if echo "$DIFF_CONTENT" | grep -qE "from ['\"]@mantine/"; then
  has_mantine=true
fi

# Check for GraphQL patterns
if echo "$DIFF_CONTENT" | grep -qE "(useQuery|useMutation|gql\`|\.graphql)" || \
   echo "$CHANGED_FILES" | grep -qE '\.graphql$'; then
  has_graphql=true
fi

# Generate checklist
echo "# PR Review Checklist"
echo ""

# Always include core checklist
echo "## General"
echo "- [ ] Correctness — does it do what it claims?"
echo "- [ ] Edge cases — null, empty, boundary values handled?"
echo "- [ ] Security — no injection, XSS, or data leaks?"
echo "- [ ] Naming — clear, consistent, self-documenting?"
echo "- [ ] Simplicity — is there a simpler way?"
echo ""

# JavaScript
if [[ "$has_js" == "true" || "$has_ts" == "true" ]]; then
  echo "## JavaScript / TypeScript"
  echo "- [ ] No \`var\` — use \`const\` (preferred) or \`let\`"
  echo "- [ ] Pure functions where possible; side effects isolated"
  echo "- [ ] Immutable patterns (\`map\`/\`filter\`/\`reduce\` over mutation)"
  echo "- [ ] Proper error handling (no silent catches)"
  echo "- [ ] No magic numbers/strings — named constants used"
  if [[ "$has_ts" == "true" ]]; then
    echo "- [ ] Strict typing — no \`any\` escape hatches"
    echo "- [ ] Discriminated unions over type assertions"
    echo "- [ ] Interfaces for object shapes, types for unions/intersections"
  fi
  echo ""
fi

# React
if [[ "$has_jsx" == "true" || "$has_tsx" == "true" ]]; then
  echo "## React"
  echo "- [ ] Components are small and single-responsibility"
  echo "- [ ] No unnecessary re-renders (\`useMemo\`/\`useCallback\` where needed)"
  echo "- [ ] Effects have correct dependency arrays"
  echo "- [ ] No direct DOM manipulation — use refs if needed"
  echo "- [ ] Event handlers don't create closures in render"
  echo ""
fi

# Mantine
if [[ "$has_mantine" == "true" ]]; then
  echo "## Mantine"
  echo "- [ ] Using Mantine components instead of raw HTML equivalents"
  echo "- [ ] Theme tokens used for colors/spacing (no hardcoded values)"
  echo "- [ ] Responsive props used where applicable"
  echo "- [ ] \`useForm\` for form state management"
  echo ""
fi

# Tailwind
if [[ "$has_tailwind" == "true" ]]; then
  echo "## Tailwind"
  echo "- [ ] Utility classes extracted to CSS Modules for reuse"
  echo "- [ ] No conflicting utilities on same element"
  echo "- [ ] Responsive utilities use mobile-first approach"
  echo "- [ ] Design tokens (theme values) used over arbitrary values"
  echo ""
fi

# GraphQL
if [[ "$has_graphql" == "true" ]]; then
  echo "## GraphQL"
  echo "- [ ] Queries use codegen TypedDocumentNode — no raw gql with manual types"
  echo "- [ ] No dynamic query construction or string interpolation"
  echo "- [ ] All three states handled: data, loading, error"
  echo "- [ ] Fragments colocated with consuming components"
  echo "- [ ] Operations named VerbNoun in PascalCase"
  echo "- [ ] refetchQueries uses document nodes, not strings"
  echo ""
fi

# CSS/SASS
if [[ "$has_css" == "true" || "$has_scss" == "true" ]]; then
  echo "## CSS / SASS"
  echo "- [ ] BEM naming for custom classes"
  echo "- [ ] No \`!important\` unless overriding third-party"
  echo "- [ ] Nesting max 3 levels deep"
  if [[ "$has_scss" == "true" ]]; then
    echo "- [ ] SASS variables/mixins for repeated values"
  fi
  echo ""
fi

# Tests
if [[ "$has_test" == "true" ]]; then
  echo "## Tests"
  echo "- [ ] Tests describe behavior, not implementation"
  echo "- [ ] Arrange-Act-Assert pattern followed"
  echo "- [ ] No test interdependencies"
  echo "- [ ] Edge cases and error paths covered"
  echo "- [ ] Mocks are minimal and scoped"
  echo ""
fi

# Check if new code lacks tests
non_test_code=$(echo "$CHANGED_FILES" | grep -E '\.(js|ts|jsx|tsx)$' | grep -vE '\.(test|spec)\.' | grep -v '__tests__' || true)
if [[ -n "$non_test_code" && "$has_test" == "false" ]]; then
  echo "## Missing Tests"
  echo "- [ ] **No test files changed** — verify adequate coverage for:"
  while IFS= read -r f; do
    echo "  - \`$f\`"
  done <<< "$non_test_code"
  echo ""
fi
