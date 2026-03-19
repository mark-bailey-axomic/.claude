---
name: merge-conflict
description: >
  Resolve git merge conflicts intelligently. Detects conflict type (merge, rebase, cherry-pick),
  analyzes both sides with three-way context, suggests resolutions, and applies them. Use this
  skill whenever the user wants to resolve conflicts, fix merge conflicts, or handle rebase
  conflicts. Triggers on phrases like "resolve conflicts", "fix merge conflict", "help with
  rebase conflict", "merge conflict", even if they don't say "/merge-conflict" explicitly.
---

# Merge Conflict Resolution Skill

Detect, analyze, and resolve git merge conflicts with context-aware suggestions.

## Flags

Parse these from the user's prompt or arguments:

| Flag | Short | Description |
|------|-------|-------------|
| `--strategy <s>` | `-s <s>` | Resolution strategy: `smart` (default), `ours`, `theirs` |
| `--file <path>` | `-f <path>` | Resolve only this file. Omit to resolve all. |
| `--dry-run` | `-d` | Show suggested resolutions without applying. |
| `--continue` | `-c` | Skip analysis, just run the appropriate continue command. |
| `--abort` | `-a` | Abort the current merge/rebase/cherry-pick operation. |

## Workflow

### 1. Detect conflict state

Run in parallel:

```bash
# What operation caused the conflict?
ls .git/MERGE_HEAD 2>/dev/null && echo "STATE:merge"
ls .git/rebase-merge 2>/dev/null && echo "STATE:rebase"
ls .git/rebase-apply 2>/dev/null && echo "STATE:rebase-apply"
ls .git/CHERRY_PICK_HEAD 2>/dev/null && echo "STATE:cherry-pick"

# Current branch
git rev-parse --abbrev-ref HEAD 2>/dev/null || cat .git/rebase-merge/head-name 2>/dev/null | sed 's|refs/heads/||'

# List conflicted files
git diff --name-only --diff-filter=U

# Conflict summary
git diff --stat --diff-filter=U
```

**Branch safety check**: Verify the current branch name starts with the `EMPLOYEE_CODE` from `.env` (format: `{EMPLOYEE_CODE}_`) or starts with `claude_`. If it doesn't, STOP and warn — do not modify files on an unauthorized branch.

**No conflicts check**: If `git diff --name-only --diff-filter=U` returns empty and `--continue` was passed, run the appropriate continue command and exit. If no conflicts and no `--continue`/`--abort`, inform the user there's nothing to resolve.

**Abort**: If `--abort` flag is set, run the appropriate abort command based on detected state and exit:

```bash
# merge:
git merge --abort
# rebase:
git rebase --abort
# cherry-pick:
git cherry-pick --abort
```

**Uncommitted changes check**: Before modifying any files, check for uncommitted changes unrelated to the conflict:

```bash
git stash list
git status --porcelain
```

If there are unstaged changes to non-conflicted files, STOP and warn the user — do not proceed until they stash or commit those changes.

### 2. Triage conflicted files

For each conflicted file (or just `--file` if specified):

```bash
# Classify text vs binary
file <conflicted-file>

# File size (line count)
wc -l < <conflicted-file>

# Three-way context using git stages:
# Stage 1 = common ancestor, Stage 2 = ours, Stage 3 = theirs
git show :1:<file> > /dev/null 2>&1 && echo "HAS_ANCESTOR" || echo "NEW_FILE"
git diff :1:<file> :2:<file> 2>/dev/null   # What "ours" changed vs ancestor
git diff :1:<file> :3:<file> 2>/dev/null   # What "theirs" changed vs ancestor
```

For rebase, also show the commit being applied:

```bash
cat .git/rebase-merge/message 2>/dev/null
```

**Binary files**: Cannot auto-resolve. Report them and ask the user to pick `--ours` or `--theirs`:

```bash
git checkout --ours <file>    # or --theirs
git add <file>
```

**Large files (>5000 lines)**: Warn before reading. Ask user to confirm or narrow scope with `--file`.

### 3. Analyze conflicts

For each text-based conflicted file, read the full file content. For each conflict marker block (`<<<<<<<` through `>>>>>>>`):

1. Extract the "ours" block and "theirs" block
2. Retrieve the common ancestor via `git show :1:<file>`
3. Determine **intent** of each side:
   - What lines were added/removed vs the ancestor?
   - Are both sides making the same conceptual change?
   - Are changes in non-overlapping logical regions (different functions)?
   - Is one side a superset of the other?

**Strategy application**:

- `--ours`: take our version for every conflict block
- `--theirs`: take their version for every conflict block
- `--smart` (default): for each conflict block independently:
  - If changes are in non-overlapping regions → combine both
  - If one side is a superset → take the superset
  - If both sides make the same semantic change differently → pick the more complete version
  - If genuinely contradictory → present both options to the user with a recommendation

### 4. Apply resolutions

If `--dry-run`, show the proposed resolution for each file as a diff and stop.

Otherwise, for each file:

1. Write the resolved content using the Edit tool
2. Stage the file:

```bash
git add <resolved-file>
```

After all files are resolved, verify none remain:

```bash
git diff --name-only --diff-filter=U
```

### 5. Continue the operation

If all conflicts are resolved (no unmerged files remain), run the appropriate continue based on state detected in step 1:

```bash
# merge:
git merge --continue

# rebase / rebase-apply:
git rebase --continue

# cherry-pick:
git cherry-pick --continue
```

If the continue triggers **new conflicts** (common during rebase with multiple commits), loop back to step 1 automatically.

### 6. Report back

Output:
- Conflict type resolved (merge/rebase/cherry-pick)
- Files resolved and strategy used per file
- Whether the operation completed or has more commits to process (rebase)
- Any files that required manual user input
- Warnings (binary files, large files, uncommitted changes, etc.)
