---
name: pr
description: Create or update a GitHub pull request with Jira integration, smart base branch detection, and test checklists. Use this skill whenever the user wants to create a PR, update a PR, open a pull request, or push changes for review. Triggers on phrases like "create pr", "open pr", "update pr", "push for review", "make a pull request", even if they don't say "/pr" explicitly.
---

# PR Creation & Update Skill

Create or update GitHub pull requests with consistent formatting, Jira integration, and smart defaults.

## Flags

Parse these from the user's prompt or arguments:

| Flag | Short | Description |
|------|-------|-------------|
| `--jira <ID>` | `-j <ID>` | Jira issue ID (e.g. `PROJ-123`). Added to title and body. |
| `--ai-assisted` | `-a` | Add `claude-code-assisted` label (only if label exists on repo) and agent signature to body. |
| `--update` | `-u` | Update an existing PR instead of creating a new one. |

## Workflow

### 1. Gather context

Run these in parallel to understand the current state:

```bash
# Current branch
git rev-parse --abbrev-ref HEAD

# Tracking/base branch — the upstream branch this was created from
git config branch.$(git rev-parse --abbrev-ref HEAD).merge | sed 's|refs/heads/||'

# If no tracking branch, fall back to checking the merge base against common defaults
# Try: main, master, develop, dev — use whichever has the closest merge base

# All commits on this branch since diverging from base
git log --oneline $(git merge-base HEAD <base-branch>)..HEAD

# Full diff against base
git diff <base-branch>...HEAD

# Check if a PR already exists for this branch
gh pr view --json number,title,body,baseRefName 2>/dev/null
```

**Branch safety check**: Verify the current branch name starts with the `EMPLOYEE_CODE` from `.env` (format: `{EMPLOYEE_CODE}_`) or starts with `claude_`. If it doesn't, STOP and warn the user — do not create or update a PR from an unauthorized branch.

### 2. Determine base branch

The target branch is the **upstream/parent branch** of the current branch, not hardcoded to `main`. Detection order:

1. If `--update` and a PR already exists: use the existing PR's `baseRefName`
2. `git config branch.<current>.merge` (tracking branch)
3. Find the nearest ancestor branch dynamically:
   ```bash
   # Fetch latest remote refs
   git fetch --prune
   # Get all remote branches except the current one
   git branch -r --format='%(refname:short)' | sed 's|origin/||' | grep -v "^$(git rev-parse --abbrev-ref HEAD)$"
   ```
   For each candidate branch, compute `git merge-base HEAD <candidate>` and pick the one whose merge-base is closest to HEAD (fewest commits between merge-base and HEAD). This finds the true parent branch regardless of naming convention.
4. If all else fails, ask the user

### 3. Analyze changes

Read the commit log and diff from step 1. Produce:

- **Title**: A concise summary of the changes (under 70 chars before Jira prefix)
- **Change summary**: Bulleted list of what changed and why
- **Test checklist**: Concrete steps someone could follow to verify the changes work — think about what a reviewer would actually need to test

### 4A. Create PR (default)

Format the title:
- With Jira: `[PROJ-123] - Short description of changes`
- Without Jira: `Short description of changes`

Format the body using this template:

```markdown
## Summary
<bulleted change description>

## Jira
<If --jira flag provided: Jira issue ID, e.g. PROJ-123>
<If no --jira flag: omit this section entirely>

## Test Plan
- [ ] Test step 1
- [ ] Test step 2
- [ ] ...

<If --ai-assisted flag: add the signature line below>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Create the PR:

```bash
# Push the branch first
git push -u origin <current-branch>

# Build the gh command
gh pr create \
  --base <base-branch> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body content>
EOF
)" \
  --draft
```

**Always create as draft** — no exceptions.

After creation, handle the label:

```bash
# Only if --ai-assisted flag is set
# First check if label exists on the repo
gh label list --search "claude-code-assisted" --json name --jq '.[].name' | grep -q "claude-code-assisted"
# If the above exits 0, apply it:
gh pr edit <pr-number> --add-label "claude-code-assisted"
# If the label doesn't exist, skip silently — never create it
```

### 4B. Update PR (`--update`)

When updating an existing PR:

1. Fetch the existing PR body: `gh pr view --json body --jq .body`
2. Analyze the **new** commits/changes since the PR was created or last updated
3. **Append** a new section to the existing body — do not replace existing content unless something is factually wrong or outdated
4. Update the title only if the scope of changes has meaningfully shifted
5. Add any new test steps to the checklist

Append format:

```markdown

---

## Update: <short description of what changed>
<bulleted list of new changes>

### Additional Test Steps
- [ ] New test step 1
- [ ] New test step 2

<If --ai-assisted and signature not already in body, add it>
```

```bash
gh pr edit <pr-number> \
  --title "<updated-title-if-changed>" \
  --body "$(cat <<'EOF'
<full updated body>
EOF
)"
```

If `--ai-assisted` is set and the label isn't already on the PR, apply it (same check-then-apply logic as creation).

### 5. Report back

After creating or updating, output:
- The PR URL
- A brief summary of what was done
- Any warnings (e.g., label didn't exist, no tracking branch found)
