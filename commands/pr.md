---
description: Create or modify pull request following conventions
allowed-tools: Bash(gh:*), Bash(git:*), AskUserQuestion
argument-hint: "[ticket-id]"
---

# Create or Modify a Pull Request

Manage PRs following project conventions.

## Pre-flight Checks

1. **Check current branch**

   ```bash
   git branch --show-current
   ```

   - STOP if on `staging`, `develop`, `development`, `main`, or `master`

2. **Check for existing PR**

   ```bash
   gh pr view --json number,url 2>/dev/null
   ```

   - If PR exists → go to "Modifying a PR" section

## Creating a PR

1. **Push branch to remote**

   ```bash
   git push -u origin HEAD
   ```

2. **Determine target branch**

   ```bash
   # Check which base branch exists
   git show-ref --verify --quiet refs/remotes/origin/staging && echo staging || \
   git show-ref --verify --quiet refs/remotes/origin/develop && echo develop || \
   echo main
   ```

   - Prefer: `staging` → `develop` → `main`
   - NEVER target `master` or `main` directly (ask user to confirm if only option)

3. **Analyze changes for summary**

   ```bash
   git log origin/{target-branch}..HEAD --oneline
   git diff origin/{target-branch}..HEAD --stat
   ```

   - Use commits + diff to generate meaningful summary
   - Don't just use generic descriptions

4. **Handle ticket ID**

   - If user provided ticket ID → use it
   - If not provided → ask user if one is available
   - If none available → omit from title/body

5. **Create PR**

   ```bash
   gh pr create --draft --assignee @me --base {target-branch} --title "{title}" --body "$(cat <<'EOF'
   {body}
   EOF
   )"
   ```

## PR Title Format

**With ticket:**
`[{TICKET-ID}] brief-summary`

**Without ticket:**
`brief-summary`

Examples:

- `[ABC-123] fix login validation`
- `add user profile page`

## PR Body Template

**With ticket:**

```markdown
## Summary

- Brief change summary
- Key context

## Test Instructions

- Step-by-step testing guide (if applicable)

## Ticket

[{TICKET-ID}](https://axomic.atlassian.net/browse/{TICKET-ID})

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Without ticket:**

```markdown
## Summary

- Brief change summary
- Key context

## Test Instructions

- Step-by-step testing guide (if applicable)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Modifying a PR

When updating an existing PR:

1. **Convert to draft first**

   ```bash
   gh pr ready --undo
   ```

2. **Push code changes**

   ```bash
   git push
   ```

3. **Edit title/body** (if needed)

   ```bash
   gh pr edit --title "{new-title}" --body "$(cat <<'EOF'
   {new-body}
   EOF
   )"
   ```

## Error Handling

- **PR create fails**: Check branch pushed to remote (`git push -u origin HEAD`)
- **No upstream**: Push branch first before creating PR
- **Permission denied**: Verify `gh auth status`

## Rules

- Always draft mode on create
- Always assign to self (`@me`)
- Never target `master`/`main`/`develop` without confirmation
- Include ticket link only if ticket ID available
- Update description + revert to draft on changes
