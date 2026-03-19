#!/usr/bin/env bash
# select-guidelines.sh - Detect which coding guideline references are relevant
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: select-guidelines.sh [-h] [--diff | PROJECT_DIR]

Detect which coding guideline reference files are relevant.

Modes:
  PROJECT_DIR   Scan project directory (default: current directory)
  --diff        Read unified diff from stdin (e.g. gh pr diff 123 | select-guidelines.sh --diff)

Options:
  -h, --help    Show this help message

Output: one reference filename per line (e.g. javascript.md)
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

# Always include javascript
guidelines=("javascript.md")

# Helper: add guideline if not already present
add() {
  local g="$1"
  for existing in "${guidelines[@]}"; do
    [[ "$existing" == "$g" ]] && return
  done
  guidelines+=("$g")
}

if [[ "${1:-}" == "--diff" ]]; then
  # --diff mode: read unified diff from stdin
  DIFF_INPUT="$(cat)"

  # Extract file paths from diff headers (+++ b/path/to/file)
  FILES="$(echo "$DIFF_INPUT" | grep -E '^\+\+\+ b/' | sed 's|^+++ b/||' || true)"
  # Extract added lines (skip +++ headers)
  ADDED="$(echo "$DIFF_INPUT" | grep -E '^\+[^+]' || true)"

  # TypeScript
  if echo "$FILES" | grep -qE '\.tsx?$'; then
    add "typescript.md"
  fi

  # React
  if echo "$FILES" | grep -qE '\.[jt]sx$'; then
    add "react.md"
  fi

  # CSS/SASS
  if echo "$FILES" | grep -qE '\.(css|scss)$'; then
    add "css-or-sass.md"
  fi

  # Mantine
  if echo "$ADDED" | grep -qE '@mantine/'; then
    add "mantine.md"
  fi

  # GraphQL
  if echo "$ADDED" | grep -qE '@apollo/client|from .graphql|graphql-codegen'; then
    add "graphql.md"
  fi

  # Tailwind
  if echo "$FILES" | grep -qE 'tailwind\.config' || echo "$ADDED" | grep -qE 'tailwindcss|className='; then
    add "tailwind.md"
  fi

  # Next.js
  if echo "$FILES" | grep -qE 'next\.config' || echo "$ADDED" | grep -qE 'from .next/|next/image|next/font|next/link|next/navigation'; then
    add "nextjs.md"
  fi

  # Astro
  if echo "$FILES" | grep -qE '\.astro$|astro\.config' || echo "$ADDED" | grep -qE 'from .astro:|astro:content|astro:transitions'; then
    add "astro.md"
  fi

  # Tests
  if echo "$FILES" | grep -qE '\.(test|spec)\.[jt]sx?$'; then
    add "test.md"
  fi

else
  # Project directory mode (existing behavior)
  PROJECT_DIR="${1:-.}"
  PROJECT_DIR="${PROJECT_DIR//\\//}"
  PKG="$PROJECT_DIR/package.json"

  has_dep() {
    local pattern="$1"
    if command -v jq &>/dev/null && [[ -f "$PKG" ]]; then
      jq -e "(.dependencies // {} | keys[]) + \",\" + ((.devDependencies // {} | keys[]) // empty)" "$PKG" 2>/dev/null | grep -q "$pattern" && return 0
    elif [[ -f "$PKG" ]]; then
      grep -q "\"$pattern" "$PKG" && return 0
    fi
    return 1
  }

  if has_dep "typescript" || [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
    add "typescript.md"
  fi

  if has_dep "react"; then
    add "react.md"
  fi

  if has_dep "@mantine/"; then
    add "mantine.md"
  fi

  if has_dep "@apollo/client" || has_dep "graphql" || has_dep "@graphql-codegen/"; then
    add "graphql.md"
  fi

  if has_dep "tailwindcss" || compgen -G "$PROJECT_DIR/tailwind.config.*" &>/dev/null; then
    add "tailwind.md"
  fi

  # Next.js
  if has_dep "next" || [[ -f "$PROJECT_DIR/next.config.js" ]] || [[ -f "$PROJECT_DIR/next.config.mjs" ]] || [[ -f "$PROJECT_DIR/next.config.ts" ]]; then
    add "nextjs.md"
  fi

  # Astro
  if has_dep "astro" || compgen -G "$PROJECT_DIR/astro.config.*" &>/dev/null; then
    add "astro.md"
  fi

  if has_dep "jest" || has_dep "vitest" || has_dep "@testing-library/"; then
    add "test.md"
  fi

  if has_dep "sass" || has_dep "node-sass"; then
    add "css-or-sass.md"
  elif find "$PROJECT_DIR" -maxdepth 3 \( -name "*.scss" -o -name "*.css" \) -not -path "*/node_modules/*" -print -quit 2>/dev/null | grep -q .; then
    add "css-or-sass.md"
  fi
fi

# Output deduplicated results
printf '%s\n' "${guidelines[@]}"
