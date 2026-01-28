#!/bin/bash
# Create git branch following naming conventions
# Usage: create-branch [description] [type] [-c|--checkout] [-b|--base <branch>] [--json]
# Types: feature, bug, defect, chore, hotfix, spike, debt
# Options:
#   -c, --checkout       Also checkout the branch after creating
#   -b, --base <branch>  Base branch to branch from (default: staging)
#                        Use "current" to branch from current branch
#   --json               Output only JSON (errors also in JSON)
#   -h, --help           Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/__branch.sh"

VALID_TYPES="feature bug defect chore hotfix spike debt"
DEFAULT_BASE="staging"
do_checkout=false
specified_base=""
json_output=false

# JSON output helpers
json_error() {
  echo "{\"success\":false,\"error\":\"$1\"}"
  exit 1
}

json_success() {
  local branch="$1" base="$2" checked_out="$3"
  echo "{\"success\":true,\"branch\":\"$branch\",\"base\":\"$base\",\"checkedOut\":$checked_out}"
}

error_msg() {
  if $json_output; then
    json_error "$1"
  else
    echo "Error: $1" >&2
    exit 1
  fi
}

# Help function
show_help() {
  cat << EOF
Usage: create-branch [summary] [type] [-c|--checkout] [-b|--base <branch>]

Create a git branch following naming conventions.
Include ticket ID in summary if needed (e.g., "SHRED-123 my feature").

Arguments:
  summary         Branch summary (spaces allowed, will be converted to kebab-case)
  type            Branch type: $VALID_TYPES

Options:
  -c, --checkout       Also checkout the branch after creating
  -b, --base <branch>  Base branch to branch from (default: $DEFAULT_BASE)
                       Use "current" to branch from current branch
  --json               Output only JSON (errors also in JSON)
  -h, --help           Show this help message

Examples:
  create-branch "SHRED-123 my feature" feature
  create-branch "my bugfix" bug -c
  create-branch "my feature" feature -b current
  create-branch "hotfix 123" hotfix -b develop -c
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
  error_msg "Not in a git repository"
fi

# Parse flags
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--checkout)
      do_checkout=true
      shift
      ;;
    --json)
      json_output=true
      shift
      ;;
    -b|--base)
      if [[ -z "$2" || "$2" == -* ]]; then
        error_msg "-b/--base requires a branch name"
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

# Parse args (both required)
if [[ $# -ne 2 ]]; then
  error_msg "Both summary and type are required"
fi

summary="$1"
branch_type="$2"

# Validate type
if ! echo "$VALID_TYPES" | grep -qw "$branch_type"; then
  error_msg "Invalid type '$branch_type'. Must be one of: $VALID_TYPES"
fi

# Determine base branch
if [[ "$specified_base" == "current" ]]; then
  base_branch=$(git branch --show-current)
  [[ -z "$base_branch" ]] && error_msg "Detached HEAD"
  base_ref="$base_branch"
else
  base_branch="${specified_base:-$DEFAULT_BASE}"
  base_ref=$(resolve_branch_ref "$base_branch") || error_msg "Branch '$base_branch' not found"
fi

# Build branch name
branch_name=$(make_branch_name "$branch_type" "$summary")

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  error_msg "Branch '$branch_name' already exists locally"
fi

if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
  error_msg "Branch '$branch_name' already exists on remote"
fi

# Create branch (fetch only if using remote ref)
if $json_output; then
  [[ "$base_ref" == origin/* ]] && git fetch origin --quiet >/dev/null 2>&1
  if ! git branch "$branch_name" "$base_ref" >/dev/null 2>&1; then
    json_error "Failed to create branch"
  fi
  if $do_checkout && ! git checkout "$branch_name" --quiet >/dev/null 2>&1; then
    json_error "Branch created but checkout failed"
  fi
else
  [[ "$base_ref" == origin/* ]] && git fetch origin
  git branch "$branch_name" "$base_ref"
  $do_checkout && git checkout "$branch_name"
fi

# Output result
if $json_output; then
  json_success "$branch_name" "$base_branch" "$do_checkout"
else
  if $do_checkout; then
    echo "Created and checked out branch: $branch_name (from $base_branch)"
  else
    echo "Created branch: $branch_name (from $base_branch)"
  fi
fi
