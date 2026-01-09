#!/bin/bash
# Create git branch following naming conventions
# Usage: create-branch [description] [type] [-c|--checkout] [-b|--base <branch>]
# Types: feature, bug, defect, chore, hotfix, spike, debt
# Options:
#   -c, --checkout       Also checkout the branch after creating
#   -b, --base <branch>  Base branch to branch from (default: staging)
#                        Use "current" to branch from current branch
#   -h, --help           Show this help message

set -e

SCRIPT_DIR="$(dirname "$0")"
VALID_TYPES="feature bug defect chore hotfix spike debt"
DEFAULT_BASE="staging"
do_checkout=false
specified_base=""

# Help function
show_help() {
  cat << EOF
Usage: create-branch [description] [type] [-c|--checkout] [-b|--base <branch>]

Create a git branch following naming conventions.
Include ticket ID in description if needed (e.g., SHRED-123-my-feature).

Arguments:
  description     Branch description in kebab-case (spaces converted automatically)
  type            Branch type: $VALID_TYPES

Options:
  -c, --checkout       Also checkout the branch after creating
  -b, --base <branch>  Base branch to branch from (default: $DEFAULT_BASE)
                       Use "current" to branch from current branch
  -h, --help           Show this help message

Examples:
  create-branch SHRED-123-my-feature feature
  create-branch my-bugfix bug -c
  create-branch my-feature feature -b current
  create-branch hotfix-123 hotfix -b develop -c
EOF
  exit 0
}

# Check for help flag first
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help ;;
  esac
done

# Check if in git repo
if ! git rev-parse --git-dir &>/dev/null; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

# Parse flags
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--checkout)
      do_checkout=true
      shift
      ;;
    -b|--base)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: -b/--base requires a branch name" >&2
        exit 1
      fi
      specified_base="$2"
      shift 2
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done
set -- "${args[@]}"

# Get employee code
if ! emp_code=$("$SCRIPT_DIR/employee-code.sh" 2>/dev/null); then
  echo "Error: Failed to get employee code from employee-code.sh" >&2
  exit 1
fi

if [[ -z "$emp_code" ]]; then
  echo "Error: Employee code is empty" >&2
  exit 1
fi

# Parse args
description=""
branch_type=""

case $# in
  2)
    description="$1"
    branch_type="$2"
    ;;
  1)
    if echo "$VALID_TYPES" | grep -qw "$1"; then
      branch_type="$1"
    else
      description="$1"
    fi
    ;;
esac

# Interactive prompts for missing info
if [[ -z "$description" ]]; then
  read -rp "Description (kebab-case): " description
fi

if [[ -z "$branch_type" ]]; then
  echo "Types: $VALID_TYPES"
  read -rp "Type: " branch_type
fi

# Validate type
if ! echo "$VALID_TYPES" | grep -qw "$branch_type"; then
  echo "Error: Invalid type '$branch_type'. Must be one of: $VALID_TYPES" >&2
  exit 1
fi

# Convert description to kebab-case
description=$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

# Determine base branch
base_branch=""
base_ref=""

if [[ -n "$specified_base" ]]; then
  if [[ "$specified_base" == "current" ]]; then
    base_branch=$(git branch --show-current)
    if [[ -z "$base_branch" ]]; then
      echo "Error: Not on a branch (detached HEAD)" >&2
      exit 1
    fi
    base_ref="$base_branch"
  else
    base_branch="$specified_base"
    # Check if specified base exists
    if git show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
      base_ref="origin/$base_branch"
    elif git show-ref --verify --quiet "refs/heads/$base_branch"; then
      base_ref="$base_branch"
    else
      echo "Error: Base branch '$base_branch' not found" >&2
      exit 1
    fi
  fi
else
  # Default to staging
  base_branch="$DEFAULT_BASE"
  if git show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
    base_ref="origin/$base_branch"
  elif git show-ref --verify --quiet "refs/heads/$base_branch"; then
    base_ref="$base_branch"
  else
    echo "Error: Default base branch '$base_branch' not found" >&2
    exit 1
  fi
fi

# Build branch name
branch_name="${emp_code}_${description}_${branch_type}"

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  echo "Error: Branch '$branch_name' already exists locally" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
  echo "Error: Branch '$branch_name' already exists on remote" >&2
  exit 1
fi

# Create branch
git fetch origin
git branch "$branch_name" "$base_ref"

if $do_checkout; then
  git checkout "$branch_name"
  echo "Created and checked out branch: $branch_name (from $base_branch)"
else
  echo "Created branch: $branch_name (from $base_branch)"
fi
