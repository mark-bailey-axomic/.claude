#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
DRY_RUN=false
KEEP_CONVERSATIONS=false
INCLUDE_HISTORY=false
FORCE_WORKTREES=false
TOTAL_FREED=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Clean up ephemeral files from ~/.claude directory.

Options:
  --dry-run             Preview what would be deleted without deleting
  --keep-conversations  Skip purging project conversation logs
  --include-history     Also purge history.jsonl
  --force-worktrees     Delete ALL worktrees, not just orphaned ones
  -h, --help            Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --keep-conversations) KEEP_CONVERSATIONS=true; shift ;;
    --include-history) INCLUDE_HISTORY=true; shift ;;
    --force-worktrees) FORCE_WORKTREES=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Get size in bytes (macOS compatible)
dir_size_bytes() {
  if [[ -e "$1" ]]; then
    du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
  else
    echo 0
  fi
}

human_size() {
  local bytes=$1
  if (( bytes >= 1073741824 )); then
    printf "%.1fGB" "$(echo "$bytes / 1073741824" | bc -l)"
  elif (( bytes >= 1048576 )); then
    printf "%.1fMB" "$(echo "$bytes / 1048576" | bc -l)"
  elif (( bytes >= 1024 )); then
    printf "%.1fKB" "$(echo "$bytes / 1024" | bc -l)"
  else
    printf "%dB" "$bytes"
  fi
}

action_label() {
  if $DRY_RUN; then echo "[DRY RUN]"; else echo "[CLEAN]"; fi
}

purge_dir() {
  local dir="$1"
  local label="$2"
  if [[ ! -d "$dir" ]]; then return; fi
  local size
  size=$(dir_size_bytes "$dir")
  if (( size == 0 )); then
    if ! $DRY_RUN; then
      rmdir "$dir" 2>/dev/null || true
    fi
    return
  fi
  TOTAL_FREED=$((TOTAL_FREED + size))
  echo "  $(action_label) $label: $(human_size "$size")"
  if ! $DRY_RUN; then
    rm -rf "${dir:?}"/*
    find "$dir" -mindepth 1 -maxdepth 1 -name '.*' -exec rm -rf {} + 2>/dev/null || true
    rmdir "$dir" 2>/dev/null || true
  fi
}

purge_file() {
  local file="$1"
  local label="$2"
  if [[ ! -f "$file" ]]; then return; fi
  local size
  size=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
  if (( size == 0 )); then return; fi
  TOTAL_FREED=$((TOTAL_FREED + size))
  echo "  $(action_label) $label: $(human_size "$size")"
  if ! $DRY_RUN; then
    rm -f "$file"
  fi
}

clean_worktrees() {
  local wt_dir="${WORKTREES_DIR:-${CLAUDE_DIR}/worktrees}"
  if [[ ! -d "$wt_dir" ]]; then return; fi

  echo ""
  echo "Worktrees:"

  if $FORCE_WORKTREES; then
    local size
    size=$(dir_size_bytes "$wt_dir")
    if (( size == 0 )); then
      echo "  No worktrees found."
      return
    fi
    TOTAL_FREED=$((TOTAL_FREED + size))
    echo "  $(action_label) ALL worktrees: $(human_size "$size")"
    if ! $DRY_RUN; then
      rm -rf "${wt_dir:?}"/*
    fi
    return
  fi

  # Remove orphaned worktrees (not registered with git)
  local found_orphan=false
  local worktrees=()
  while IFS= read -r -d '' wt; do
    worktrees+=("$wt")
  done < <(find "$wt_dir" -mindepth 2 -maxdepth 2 -type d -print0 2>/dev/null)

  for wt in "${worktrees[@]+"${worktrees[@]}"}"; do
    [[ -z "$wt" ]] && continue
    local branch_name repo_name
    branch_name=$(basename "$wt")
    repo_name=$(basename "$(dirname "$wt")")

    # Check if worktree is registered with any git repo
    local is_registered=false
    if [[ -f "$wt/.git" ]]; then
      local git_dir
      git_dir=$(sed 's/gitdir: //' "$wt/.git" 2>/dev/null)
      if [[ -n "$git_dir" && -d "$git_dir" ]]; then
        is_registered=true
      fi
    fi

    if ! $is_registered; then
      found_orphan=true
      local size
      size=$(dir_size_bytes "$wt")
      TOTAL_FREED=$((TOTAL_FREED + size))
      echo "  $(action_label) orphaned: ${repo_name}/${branch_name} ($(human_size "$size"))"
      if ! $DRY_RUN; then
        rm -rf "${wt:?}"
      fi
    fi
  done

  # Clean up empty repo dirs
  if ! $DRY_RUN; then
    find "$wt_dir" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null || true
  fi

  if ! $found_orphan; then
    echo "  No orphaned worktrees found."
  fi
}

clean_conversations() {
  if $KEEP_CONVERSATIONS; then return; fi

  echo ""
  echo "Conversation logs:"

  local conv_freed=0
  for project_dir in "${CLAUDE_DIR}"/projects/*/; do
    [[ -d "$project_dir" ]] || continue

    # Remove .jsonl files (conversation logs)
    local jsonl_files=()
    while IFS= read -r -d '' f; do
      jsonl_files+=("$f")
    done < <(find "$project_dir" -maxdepth 1 -name '*.jsonl' -type f -print0 2>/dev/null)

    for f in "${jsonl_files[@]+"${jsonl_files[@]}"}"; do
      [[ -z "$f" ]] && continue
      local size
      size=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
      conv_freed=$((conv_freed + size))
      TOTAL_FREED=$((TOTAL_FREED + size))
      if ! $DRY_RUN; then
        rm -f "$f"
      fi
    done

    # Remove UUID dirs (conversation state) but NOT memory/
    local uuid_dirs=()
    while IFS= read -r -d '' d; do
      uuid_dirs+=("$d")
    done < <(find "$project_dir" -maxdepth 1 -mindepth 1 -type d ! -name 'memory' -print0 2>/dev/null)

    for d in "${uuid_dirs[@]+"${uuid_dirs[@]}"}"; do
      [[ -z "$d" ]] && continue
      local size
      size=$(dir_size_bytes "$d")
      conv_freed=$((conv_freed + size))
      TOTAL_FREED=$((TOTAL_FREED + size))
      if ! $DRY_RUN; then
        rm -rf "$d"
      fi
    done
  done

  echo "  $(action_label) project conversation logs: $(human_size "$conv_freed")"
}

# --- Main ---
echo "=== Claude Code Cleanup ==="
echo "Directory: ${CLAUDE_DIR}"
if $DRY_RUN; then
  echo "Mode: DRY RUN (no files will be deleted)"
else
  echo "Mode: LIVE (files will be deleted)"
fi
echo ""

# Current total size
echo "Current size: $(human_size "$(dir_size_bytes "$CLAUDE_DIR")")"
echo ""

# Ephemeral directories
echo "Ephemeral directories:"
purge_dir "${CLAUDE_DIR}/telemetry"       "telemetry"
purge_dir "${CLAUDE_DIR}/shell-snapshots" "shell-snapshots"
purge_dir "${CLAUDE_DIR}/file-history"    "file-history"
purge_dir "${CLAUDE_DIR}/debug"           "debug"
purge_dir "${CLAUDE_DIR}/plans"           "plans"
purge_dir "${CLAUDE_DIR}/todos"           "todos"
purge_dir "${CLAUDE_DIR}/tasks"           "tasks"
purge_dir "${CLAUDE_DIR}/backups"         "backups"
purge_dir "${CLAUDE_DIR}/cache"           "cache"
purge_dir "${CLAUDE_DIR}/session-env"     "session-env"
purge_dir "${CLAUDE_DIR}/sessions"        "sessions"
purge_dir "${CLAUDE_DIR}/paste-cache"     "paste-cache"

# Ephemeral files
echo ""
echo "Ephemeral files:"
purge_file "${CLAUDE_DIR}/firebase-debug.log"        "firebase-debug.log"
purge_file "${CLAUDE_DIR}/mcp-needs-auth-cache.json"  "mcp-needs-auth-cache.json"
purge_file "${CLAUDE_DIR}/stats-cache.json"           "stats-cache.json"

if $INCLUDE_HISTORY; then
  purge_file "${CLAUDE_DIR}/history.jsonl" "history.jsonl"
fi

# Worktrees
clean_worktrees

# Conversations
clean_conversations

# Summary
echo ""
echo "---"
echo "Total space $(if $DRY_RUN; then echo "reclaimable"; else echo "reclaimed"; fi): $(human_size "$TOTAL_FREED")"
