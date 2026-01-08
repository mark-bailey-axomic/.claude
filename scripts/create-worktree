#!/bin/bash
# Create git worktree for an existing branch

set -e

# Check if in git repo
if ! git rev-parse --git-dir &>/dev/null; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
branch="${1:-$(git branch --show-current)}"

# Check if on base branch
if [[ "$branch" =~ ^(staging|master|main|develop)$ ]]; then
  echo "Error: On base branch '$branch'. Provide branch name as argument." >&2
  echo "Usage: create-worktree <branch-name>" >&2
  exit 1
fi

# Check branch exists
if ! git show-ref --verify --quiet "refs/heads/$branch" && \
   ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  echo "Error: Branch '$branch' does not exist. Create it first with create-branch." >&2
  exit 1
fi

worktree_path="$repo_root/worktrees/$branch"

git worktree add "$worktree_path" "$branch"
echo "Created worktree at: $worktree_path"
