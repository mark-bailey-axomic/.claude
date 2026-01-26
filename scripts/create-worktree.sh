#!/bin/bash
# Create git worktree for an existing branch
# Usage: create-worktree [branch] [--json] [-h|--help]
# Options:
#   --json       Output only JSON (errors also in JSON)
#   -h, --help   Show this help message

set -e

json_output=false

# Help function
show_help() {
  cat << EOF
Usage: create-worktree [branch] [--json]

Create a git worktree for an existing branch.
Branch must be snake_case or kebab-case (contain _ or -).

Arguments:
  branch    Branch name (defaults to current branch)

Options:
  --json       Output only JSON (errors also in JSON)
  -h, --help   Show this help message

Examples:
  create-worktree mba_my-feature_feature
  create-worktree mba_bugfix_bug --json
EOF
  exit 0
}

# Check for help flag first
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help ;;
  esac
done

# JSON output helpers
json_error() {
  echo "{\"success\":false,\"error\":\"$1\"}"
  exit 1
}

json_success() {
  local branch="$1" path="$2" env_copied="$3"
  echo "{\"success\":true,\"branch\":\"$branch\",\"path\":\"$path\",\"envCopied\":$env_copied}"
}

error_msg() {
  if $json_output; then
    json_error "$1"
  else
    echo "Error: $1" >&2
    exit 1
  fi
}

# Parse flags
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      json_output=true
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done
set -- "${args[@]}"

# Check if in git repo
if ! git rev-parse --git-dir &>/dev/null; then
  error_msg "Not in a git repository"
fi

repo_root=$(git rev-parse --show-toplevel)
branch="${1:-$(git branch --show-current)}"

# Check branch provided
if [[ -z "$branch" ]]; then
  error_msg "No branch specified and not on a branch (detached HEAD?)"
fi

# Check branch format (must contain _ or -)
if [[ ! "$branch" =~ [_-] ]]; then
  error_msg "Branch '$branch' must be snake_case or kebab-case (contain _ or -)"
fi

# Check if on base branch
if [[ "$branch" =~ ^(staging|master|main|develop|development)$ ]]; then
  error_msg "On base branch '$branch'. Provide branch name as argument."
fi

# Check branch exists
if ! git show-ref --verify --quiet "refs/heads/$branch" && \
   ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  error_msg "Branch '$branch' does not exist. Create it first with create-branch."
fi

worktree_path="$repo_root/worktrees/$branch"

if $json_output; then
  if ! git worktree add "$worktree_path" "$branch" >/dev/null 2>&1; then
    json_error "Failed to create worktree"
  fi
else
  git worktree add "$worktree_path" "$branch"
  echo "Created worktree at: $worktree_path"
fi

# Copy .env if exists
env_copied=false
if [[ -f "$repo_root/.env" ]]; then
  cp "$repo_root/.env" "$worktree_path/.env"
  env_copied=true
  $json_output || echo "Copied .env to worktree"
fi

if $json_output; then
  json_success "$branch" "$worktree_path" "$env_copied"
fi
