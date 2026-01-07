---
description: Create git worktree for an existing branch
allowed-tools: Bash(git:*), AskUserQuestion
argument-hint: [branch-name]
---

# Create a Worktree

Create a worktree for an existing branch. Use `/create-branch` first if branch doesn't exist.

## Steps

1. **Check if in git repo**

   ```bash
   git rev-parse --git-dir
   ```

   If fails → cannot create worktree (not in a repo)

2. **Get repo root**

   ```bash
   git rev-parse --show-toplevel
   ```

3. **Get branch name**

   - Use provided branch name, or
   - Use current branch via `git branch --show-current`
   - If on base branch (`staging`, `master`, `main`, `develop`) → ask which branch

4. **Create worktree**

   ```bash
   git worktree add {repo-root}/worktrees/{branch-name} {branch-name}
   ```

## Notes

- Location: `{repo-root}/worktrees/{branch-name}`
- Branch must exist before creating worktree
- Use `/create-branch` to create new branches
