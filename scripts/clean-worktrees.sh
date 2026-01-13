#!/bin/bash
# Clean up worktrees whose branches no longer exist on remote
# Must be run inside a git repository

show_help() {
  cat << 'EOF'
Usage: clean-worktrees [-f|--force] [-n|--dry-run] [-h|--help]

Options:
  -f, --force    Remove worktrees even if remote branch exists (keeps remote)
  -n, --dry-run  Show what would be deleted without actually deleting
  -h, --help     Show this help message
EOF
  exit 0
}

force=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) force=true; shift ;;
    -n|--dry-run) dry_run=true; shift ;;
    -h|--help) show_help ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Check if in git repo
if ! git rev-parse --git-dir &>/dev/null; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
worktrees_dir="$repo_root/worktrees"

# Check worktrees dir exists
if [[ ! -d "$worktrees_dir" ]]; then
  echo "No worktrees directory found at: $worktrees_dir"
  exit 0
fi

# Protected branches
protected_branches="main master staging develop development"

# Employee code pattern: 3 lowercase letters
emp_code_pattern="^[a-z]{3}_"

# Fetch latest remote info
if ! git fetch --prune origin 2>/dev/null; then
  echo "Warning: Failed to fetch from remote. Results may be inaccurate." >&2
fi

deleted=()
failed=()
skipped=()

for dir in "$worktrees_dir"/*/; do
  [[ -d "$dir" ]] || continue

  dir_name=$(basename "$dir")

  # Get branch from worktree
  if ! branch=$(git -C "$dir" branch --show-current 2>/dev/null); then
    skipped+=("$dir_name: not a valid git worktree")
    continue
  fi

  if [[ -z "$branch" ]]; then
    skipped+=("$dir_name: detached HEAD")
    continue
  fi

  # Check protected branch
  for protected in $protected_branches; do
    if [[ "$branch" == "$protected" ]]; then
      skipped+=("$dir_name: protected branch '$branch'")
      continue 2
    fi
  done

  # Check employee code prefix
  if ! [[ "$branch" =~ $emp_code_pattern ]]; then
    skipped+=("$dir_name: branch '$branch' missing employee code prefix")
    continue
  fi

  # Check if branch exists on remote
  on_remote=false
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    on_remote=true
    if ! $force; then
      skipped+=("$dir_name: branch '$branch' still on remote")
      continue
    fi
  fi

  # Dry run - just report
  if $dry_run; then
    if $on_remote; then
      deleted+=("$dir_name: would remove (branch '$branch' kept on remote)")
    else
      deleted+=("$dir_name: would remove (branch '$branch' not on remote)")
    fi
    continue
  fi

  # Remove worktree registration and force delete folder
  git worktree remove --force "$dir" 2>/dev/null || true
  if rm -rf "$dir" 2>/dev/null; then
    if $on_remote; then
      deleted+=("$dir_name: removed (branch '$branch' kept on remote)")
    else
      deleted+=("$dir_name: removed (branch '$branch' not on remote)")
    fi
  else
    failed+=("$dir_name: failed to delete directory")
  fi
done

# Report
if $dry_run; then
  echo "=== Clean Worktrees Report (DRY RUN) ==="
else
  echo "=== Clean Worktrees Report ==="
fi
echo

if [[ ${#deleted[@]} -gt 0 ]]; then
  echo "DELETED (${#deleted[@]}):"
  for item in "${deleted[@]}"; do
    echo "  - $item"
  done
  echo
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "FAILED (${#failed[@]}):"
  for item in "${failed[@]}"; do
    echo "  - $item"
  done
  echo
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
  echo "SKIPPED (${#skipped[@]}):"
  for item in "${skipped[@]}"; do
    echo "  - $item"
  done
  echo
fi

if [[ ${#deleted[@]} -eq 0 && ${#skipped[@]} -eq 0 && ${#failed[@]} -eq 0 ]]; then
  echo "No worktrees found."
fi
