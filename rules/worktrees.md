# Worktrees

Location: `~/.claude/worktrees/{repo}/{branch_name}`

Creation:
```bash
git branch {branch-name}
git worktree add ~/.claude/worktrees/${REPO_NAME}/{branch-name} {branch-name}
```

## Rules

- Never check out in the primary working directory — use worktrees for isolated work
- Use `npm ci` not `npm install` (prevents lockfile rewrite)
- Run `git checkout -- .` after install to reset formatting drift
- Never commit `package-lock.json` changes unless intentional
- Cleanup: `git worktree remove ~/.claude/worktrees/${REPO_NAME}/{branch-name}` when done
- Delete local branch if fully merged: `git branch -d {branch-name}`
