#!/usr/bin/env bash
# tailwind-lint.sh - Find inline Tailwind classes in JSX/TSX that haven't been extracted to CSS Modules
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: tailwind-lint.sh [-h] [DIRECTORY]

Scans JSX/TSX files for inline Tailwind utility classes in className attributes
that haven't been extracted to CSS Modules.

Arguments:
  DIRECTORY   Path to scan (default: current directory)

Options:
  -h, --help  Show this help message

Limitation: single-line grep only; multi-line className expressions may be missed.

Output: file:line with matched Tailwind classes, summary count at end.
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

SCAN_DIR="${1:-.}"
SCAN_DIR="${SCAN_DIR//\\//}"

EXCLUDE_DIRS="node_modules|\.next|dist|build"

# Tailwind patterns to detect
# Common utilities: flex, grid, p-*, m-*, bg-*, text-*, border-*, rounded-*, shadow-*, w-*, h-*
# Responsive/state prefixes: sm:, md:, lg:, xl:, hover:, focus:, dark:, etc.
TW_PATTERN='(^|\s|"|\x27|`)(flex|grid|block|inline|hidden|relative|absolute|fixed|sticky|p-|px-|py-|pt-|pr-|pb-|pl-|m-|mx-|my-|mt-|mr-|mb-|ml-|bg-|text-|font-|border-|rounded|shadow|w-|h-|min-w-|min-h-|max-w-|max-h-|gap-|space-|overflow-|z-|opacity-|transition|duration-|ease-|animate-|cursor-|select-|items-|justify-|self-|content-|order-|col-|row-|(sm|md|lg|xl|2xl|hover|focus|active|disabled|dark|group-hover):)'

# Also detect utility merging functions
MERGE_PATTERN='(clsx|cn|twMerge|classnames)\('

count=0

while IFS= read -r file; do
  # Skip files that are primarily CSS Module consumers (every className uses styles.)
  # We want files that have raw Tailwind strings

  while IFS= read -r match; do
    # Skip lines that reference CSS Modules (styles.xxx)
    if echo "$match" | grep -q 'styles\.'; then
      continue
    fi
    echo "$match"
    count=$((count + 1))
  done < <(grep -nE "(className=|$MERGE_PATTERN)" "$file" 2>/dev/null | grep -E "$TW_PATTERN" || true)

  # Also check for merge function calls even without className
  while IFS= read -r match; do
    if echo "$match" | grep -q 'styles\.'; then
      continue
    fi
    # Avoid duplicates from className lines already caught above
    lineno=$(echo "$match" | cut -d: -f2)
    if ! grep -nE "className=" "$file" 2>/dev/null | grep -q "^${file}:${lineno}:"; then
      echo "$match"
      count=$((count + 1))
    fi
  done < <(grep -nE "$MERGE_PATTERN" "$file" 2>/dev/null | grep -vE "className=" || true)

done < <(find "$SCAN_DIR" \( -name "*.jsx" -o -name "*.tsx" \) \
  -not -regex ".*\(${EXCLUDE_DIRS}\).*" \
  2>/dev/null)

echo ""
echo "--- Tailwind lint summary ---"
if [[ $count -eq 0 ]]; then
  echo "No inline Tailwind classes found."
else
  echo "Found $count occurrence(s) of inline Tailwind classes."
  echo "Consider extracting these to CSS Modules per tailwind.md guidelines."
fi
