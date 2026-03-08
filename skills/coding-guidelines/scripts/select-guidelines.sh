#!/usr/bin/env bash
# select-guidelines.sh - Detect which coding guideline references are relevant for a project
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: select-guidelines.sh [-h] [PROJECT_DIR]

Reads package.json and project files to determine which coding guideline
reference files are relevant.

Arguments:
  PROJECT_DIR   Path to project root (default: current directory)

Options:
  -h, --help    Show this help message

Output: one reference filename per line (e.g. javascript.md)
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

PROJECT_DIR="${1:-.}"
# Normalize Windows paths
PROJECT_DIR="${PROJECT_DIR//\\//}"

PKG="$PROJECT_DIR/package.json"

# Always include javascript
echo "javascript.md"

# Helper: check if a dependency exists in package.json
has_dep() {
  local pattern="$1"
  if command -v jq &>/dev/null && [[ -f "$PKG" ]]; then
    jq -e "(.dependencies // {} | keys[]) + \",\" + ((.devDependencies // {} | keys[]) // empty)" "$PKG" 2>/dev/null | grep -q "$pattern" && return 0
  elif [[ -f "$PKG" ]]; then
    grep -q "\"$pattern" "$PKG" && return 0
  fi
  return 1
}

# TypeScript: dep or tsconfig exists
if has_dep "typescript" || [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
  echo "typescript.md"
fi

# React
if has_dep "react"; then
  echo "react.md"
fi

# Mantine
if has_dep "@mantine/"; then
  echo "mantine.md"
fi

# Tailwind: dep or config exists
if has_dep "tailwindcss" || compgen -G "$PROJECT_DIR/tailwind.config.*" &>/dev/null; then
  echo "tailwind.md"
fi

# Testing frameworks
if has_dep "jest" || has_dep "vitest" || has_dep "@testing-library/"; then
  echo "test.md"
fi

# CSS/SASS: dep or .scss files exist
if has_dep "sass" || has_dep "node-sass"; then
  echo "css-or-sass.md"
elif find "$PROJECT_DIR" -maxdepth 3 -name "*.scss" -not -path "*/node_modules/*" -print -quit 2>/dev/null | grep -q .; then
  echo "css-or-sass.md"
fi
