---
description: Review PR or current branch diff for issues
allowed-tools: Bash(gh :*), Bash(git :*), mcp__atlassian__*, Skill, AskUserQuestion
argument-hint: [pr-number] [owner/repo]
---

# Code Review

Review code changes for issues, improvements, and best practices.

## Parse Arguments

- `$ARGUMENTS` may contain: PR number, `owner/repo`, both, or neither
- PR number: numeric (e.g., `123`)
- Repo: contains `/` (e.g., `acme/webapp`)

## Pre-flight Check

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

| In Repo? | `owner/repo` arg? | PR number? | Action                                     |
| -------- | ----------------- | ---------- | ------------------------------------------ |
| No       | No                | -          | Ask for both `owner/repo` AND PR number    |
| No       | Yes               | No         | Ask for PR number (required for external)  |
| No       | Yes               | Yes        | Use `-R owner/repo` for all commands       |
| Yes      | No                | No         | Review current branch diff                 |
| Yes      | No                | Yes        | Review PR in current repo                  |
| Yes      | Yes               | No         | Ask for PR number (external repo needs it) |
| Yes      | Yes               | Yes        | Use `-R owner/repo`, ignore current repo   |

## Determine Review Target

1. **External repo (`owner/repo` provided)** → MUST have PR number; add `-R owner/repo` to all `gh` commands
2. **PR number only (in repo)** → review that PR in current repo
3. **No args (in repo)** → review current branch's diff against base

## Get Changes & Context

**PR review (in repo):**

```bash
gh pr diff {pr_number}
gh pr view {pr_number} --json number,title,body,baseRefName
```

**PR review (external repo):**

```bash
gh pr diff {pr_number} -R {owner/repo}
gh pr view {pr_number} -R {owner/repo} --json number,title,body,baseRefName
```

**Current branch (must be in repo):**

```bash
# Find base branch (staging preferred, fallback to main/master)
BASE=$(git rev-parse --verify origin/staging 2>/dev/null && echo staging || \
       git rev-parse --verify origin/main 2>/dev/null && echo main || echo master)
git diff $(git merge-base HEAD origin/$BASE)..HEAD
gh pr view --json number,title,body,baseRefName 2>/dev/null || echo "No PR found"
```

## Extract Ticket ID

1. Parse PR title/body for ticket pattern (e.g., `ABC-123`, `[ABC-123]`)
2. If found → fetch ticket via `mcp__atlassian__getJiraIssue` tool
3. If not found → skip ticket validation, note in output

## Validate Against Ticket

Compare changes to ticket requirements:

- **Scope** - do changes address what ticket asks for?
- **Completeness** - all acceptance criteria met?
- **Overreach** - changes beyond ticket scope?
- **Missing** - ticket requirements not addressed?

## Apply Language Skills

Based on files in diff, invoke relevant skills using Skill tool:

```
Skill: typescript   # for .ts/.tsx files (also covers javascript)
Skill: react        # for .tsx/.jsx components (also covers typescript, javascript)
Skill: javascript   # for .js/.jsx files
Skill: css-or-sass  # for .css/.scss/.sass/.module.css/.module.scss
```

## Review Scope

**ONLY review code in the diff output.** Do not:

- Read entire files
- Review unchanged code
- Suggest improvements outside the diff

## Review Checklist

Analyze **changed lines only** for:

- **Bugs** - logic errors, edge cases, null/undefined issues
- **Security** - injection, XSS, auth issues, secrets exposure
- **Performance** - N+1 queries, unnecessary re-renders, memory leaks
- **Types** - missing types, `any` usage, type safety
- **Tests** - missing coverage, edge cases untested
- **Naming** - unclear vars/funcs, misleading names
- **Complexity** - over-engineering, could be simpler
- **DRY** - duplicated logic that should be abstracted

## Collect Review Comments

As you review, build a list of inline comments:

```
path: src/file.ts, line: 42, body: 🔴 **Critical:** Potential null pointer
path: src/other.ts, line: 15, body: 🟡 **Suggestion:** Consider memoizing
path: src/utils.ts, line: 8, body: 🟢 **Nitpick:** Unclear variable name
```

**Line number notes:**

- Use the line number shown after `+` in diff hunk header `@@ -old,count +NEW,count @@`
- Count from NEW start to find actual line numbers for added/changed lines
- For deleted lines, use `side: LEFT` and line from `-old,count`

## Submit PR Review

Only submit when user explicitly requests.

**Get repo info (if in repo):**

```bash
gh repo view --json owner,name --jq '"\(.owner.login) \(.name)"'
```

**Submit review (no inline comments):**

```bash
# In repo:
gh pr review {pr_number} --comment --body "$(cat <<'EOF'
...body...
EOF
)"

# External repo:
gh pr review {pr_number} -R {owner/repo} --comment --body "$(cat <<'EOF'
...body...
EOF
)"
```

**Review body template:**

```markdown
## Summary

{1-2 sentence overview}

## Ticket Validation

**Ticket:** {TICKET-ID} - {title}

- ✅ {met}
- ❌ {not met}
- ⚠️ {out of scope}

## Questions

- {questions if any}

---

🤖 Reviewed with [Claude Code](https://claude.com/claude-code)
```

**Submit review with inline comments (merge-blocking):**

```bash
# Use owner/repo from user input (external) or gh repo view (in repo)
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  -f event="REQUEST_CHANGES" \
  -f body="Review summary here" \
  -f 'comments=[{"path":"src/file.ts","line":42,"body":"Comment text"}]'
```

**Approve PR:**

```bash
# In repo:
gh pr review {pr_number} --approve --body "LGTM! ✅

---
🤖 Reviewed with [Claude Code](https://claude.com/claude-code)"

# External repo:
gh pr review {pr_number} -R {owner/repo} --approve --body "LGTM! ✅

---
🤖 Reviewed with [Claude Code](https://claude.com/claude-code)"
```

## Workflow

1. Perform review silently
2. Present findings to user
3. If issues found → ask if user wants review submitted
4. If no issues → ask if user wants to approve PR
5. Only submit/approve after user confirms

## Rules

- **Only review changed lines** - never read/review entire files
- Be concise, specific
- One comment per issue, placed on most relevant line
- Prioritize critical issues
- Skip Ticket Validation section if no ticket found
- Don't praise obvious good code
- If no issues found, submit review with summary only
- Changes should address/resolve existing PR comments
