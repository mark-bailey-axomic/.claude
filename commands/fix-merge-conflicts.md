---
description: AI-assisted resolution of git merge/rebase/cherry-pick conflicts
allowed-tools: Bash(git:*, test:*, cat:*, sed:*, grep:*, cut:*, echo:*), Read, Edit, AskUserQuestion, Task
argument-hint: none
---

# Fix Merge Conflicts

Resolve git merge, rebase, cherry-pick, or stash conflicts with AI assistance.

## Pre-flight Checks

1. **Verify in git repo**

   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null
   ```

   - STOP if not in a git repo

2. **Detect conflict state** (check in this order)

   ```bash
   # 1. Check for rebase (highest priority)
   test -d "$(git rev-parse --git-dir)/rebase-merge" && echo "REBASE"
   test -d "$(git rev-parse --git-dir)/rebase-apply" && echo "REBASE"

   # 2. Check for cherry-pick
   test -f "$(git rev-parse --git-dir)/CHERRY_PICK_HEAD" && echo "CHERRY_PICK"

   # 3. Check for merge
   git rev-parse --verify MERGE_HEAD 2>/dev/null && echo "MERGE"

   # 4. Stash = unmerged files exist but no rebase/merge/cherry-pick state
   # (failed stash pop leaves conflicts without MERGE_HEAD)
   ```

   - Use first match as conflict type
   - If unmerged files exist but no rebase/merge/cherry-pick → assume STASH
   - STOP if no unmerged files: "No conflict in progress"

3. **List conflicted files**

   ```bash
   git diff --name-only --diff-filter=U
   ```

   - STOP if empty: "No conflicted files"

4. **Identify binary files** (to skip)

   ```bash
   git diff --numstat HEAD | grep "^-" | cut -f3
   ```

   - Binary files show `-` for additions/deletions
   - Warn user and skip these files

## Gather Context

1. **Branch names**

   ```bash
   git branch --show-current
   git log -1 --format=%s MERGE_HEAD 2>/dev/null
   cat "$(git rev-parse --git-dir)/rebase-merge/head-name" 2>/dev/null | sed 's|refs/heads/||'
   ```

2. **Recent commits (context only)**

   ```bash
   git log -3 --oneline HEAD
   git log -3 --oneline MERGE_HEAD 2>/dev/null
   cat "$(git rev-parse --git-dir)/rebase-merge/message" 2>/dev/null
   git log -1 --oneline CHERRY_PICK_HEAD 2>/dev/null
   ```

## Resolve Each File

Process one file at a time. For each file, resolve all conflict regions before moving to next file.

1. **Read file** using Read tool to see conflict markers

2. **Parse ALL conflicts first** - count total regions between:

   - `<<<<<<<` and `=======` (ours - may show HEAD, commit hash, or branch)
   - `=======` and `>>>>>>>` (theirs - followed by branch/commit name)

3. **Analyze** - determine intent from commit context:

   - Independent changes that can coexist?
   - Conflicting implementations of same thing?

4. **Present to user:**

   ```
   File: {path}
   Conflict {n}/{total}:

   OURS:
   {code}

   THEIRS:
   {code}

   PROPOSED:
   {resolution}

   Rationale: {why}
   ```

5. **Ask user** using AskUserQuestion tool:

   - `accept` - apply proposed resolution
   - `reject` - output text asking for guidance, then re-propose
   - `edit` - user describes desired outcome via text
   - `ours` - keep ours for THIS REGION only
   - `theirs` - keep theirs for THIS REGION only
   - `abort` - abort entire operation

6. **Apply** using Edit tool:
   - `old_string`: entire conflict region INCLUDING markers (`<<<<<<<` through `>>>>>>>`)
   - `new_string`: resolved code (no markers)

7. **Stage**

   ```bash
   git add {filename}
   ```

## Complete Operation

After all files resolved:

```bash
# Check no remaining conflicts
git diff --name-only --diff-filter=U
```

If empty, **use AskUserQuestion tool** to get permission:

"All conflicts resolved. Complete the {type}?"

Only proceed if user confirms:

**Merge:**

```bash
git commit --no-edit
```

**Rebase:**

```bash
GIT_EDITOR=true git rebase --continue
```

**Cherry-pick:**

```bash
GIT_EDITOR=true git cherry-pick --continue
```

**Stash:**

No special command needed. Changes are staged and ready.
User can commit when ready, then optionally `git stash drop` to remove the stash entry.

## Abort

At any point user can abort. Use AskUserQuestion to confirm before running:

```bash
git merge --abort       # for merge
git rebase --abort      # for rebase
git cherry-pick --abort # for cherry-pick
```

**Stash abort** - WARN user first: this discards ALL uncommitted changes, not just stash conflicts. Ask user to confirm before running:

```bash
git reset --hard
```

## Many Conflicts

If **5+ conflicted files** or files are very large:

- Use Task tool with `subagent_type: "general-purpose"` per file
- Agent prompt: "Read {file}, parse conflict markers, propose resolution with rationale for each region. Return structured list."
- Main flow: collect proposals, present to user one at a time for approval

## Error Handling

| Error                | Action                                |
| -------------------- | ------------------------------------- |
| Not in repo          | STOP                                  |
| No conflict state    | STOP: "No conflict in progress"       |
| Binary file conflict | Skip, warn user to resolve manually   |
| Edit fails           | Show error, ask for manual resolution |
| User rejects all     | Offer abort option                    |

## Rules

- Never auto-apply without user approval
- Never commit/continue without user permission
- One conflict region at a time
- Preserve code style
- Always offer abort option
- Skip binary files with warning
