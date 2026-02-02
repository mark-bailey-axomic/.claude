source "$(dirname "${BASH_SOURCE[0]}")/../../.env"

# Get the branch type based on the Jira issue type
get_branch_type() {
  local issue_type="$1"
  case "$issue_type" in
    Bug)            echo "bug" ;;
    Defect)         echo "defect" ;;
    Spike)          echo "spike" ;;
    "Technical Debt") echo "debt" ;;
    Hotfix)         echo "hotfix" ;;
    *)              echo "feature" ;;
  esac
}

# Generate a branch slug from summary and optional issue ID
make_branch_slug() {
  local summary="$1"
  local issue_id="${2:-}"
  local slug=$(echo "$summary" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '-' | \
    sed 's/[^a-z0-9_-]//g' | \
    cut -c1-40)
  if [[ -n "$issue_id" ]]; then
    echo "${issue_id}_${slug}"
  else
    echo "$slug"
  fi
}

# Make full branch name from branch type, summary, and optional issue ID
make_branch_name() {
  # Get the scripts directory
  local scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  
  local branch_type="${1}"
  local summary="$2"
  local issue_id="${3:-}"
  local branch_slug=$(make_branch_slug "$summary" "$issue_id")

  echo "${EMPLOYEE_CODE}_${branch_slug}_${branch_type}"
}

# Resolve branch to ref (prefers remote)
resolve_branch_ref() {
  local branch="$1"
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "origin/$branch"
  elif git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "$branch"
  else
    return 1
  fi
}