# Pull Requests

## Creation

- Always create as **draft** (`--draft`)
- Always assign to self (`--assignee @me`)
- Title format with Jira: `[PROJ-123] - Short description` (description under 70 chars)
- Title format without Jira: `Short description`
- Smart base branch detection order:
  1. If updating existing PR: use PR's `baseRefName`
  2. Git tracking branch
  3. Nearest ancestor branch (fewest commits between merge-base and HEAD)
  4. Ask user

## Pushing to Existing PR

1. Switch PR to draft first: `gh pr ready --undo`
2. Push changes
3. Mark ready again if appropriate: `gh pr ready`

## Auto-merge

- If PR targets a trunk branch (`main`, `master`, `develop`, `development`), enable auto-merge: `gh pr merge --auto --merge`
