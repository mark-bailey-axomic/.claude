---
description: Verify branch changes with code review and pre-PR checks
allowed-tools: Bash(gh:*), Bash(git:*), Bash(npm:*), Bash(npx:*), Bash(bun:*), Bash(yarn:*), Bash(pnpm:*), mcp__atlassian__*, Task, Read, Glob, Grep
---

# Verify Changes

Run code review and pre-PR checks on branch changes.

## Step 1: Detect Changes

```bash
BASE=$(git rev-parse --verify origin/staging 2>/dev/null && echo staging || \
       git rev-parse --verify origin/main 2>/dev/null && echo main || echo master)
git diff $(git merge-base HEAD origin/$BASE)..HEAD --stat
```

**If no changes detected (empty output):**

- Print: `No changes detected on current branch. Exiting.`
- Exit immediately - do not proceed

## Step 2: Run Pre-PR Checks

Run each check and capture pass/fail status:

### 2a. Lint

```bash
npm run lint 2>&1 || yarn lint 2>&1 || pnpm lint 2>&1 || bun lint 2>&1
```

### 2b. Prettier/Format

```bash
npm run format:check 2>&1 || npm run prettier:check 2>&1 || npx prettier --check . 2>&1
```

### 2c. TypeCheck

```bash
npm run typecheck 2>&1 || npm run type-check 2>&1 || npx tsc --noEmit 2>&1
```

### 2d. Tests

```bash
npm test 2>&1 || yarn test 2>&1 || pnpm test 2>&1 || bun test 2>&1
```

### 2e. CLAUDE.md Compliance

Check if changes comply with project CLAUDE.md:

- Read project CLAUDE.md if exists
- Verify changes follow stated conventions

## Step 3: Code Review

Invoke `/code-review` command on current branch via subagent:

```
Task tool with subagent_type="general-purpose":
"Use Skill tool to invoke 'code-review' (no arguments).
After code-review completes its analysis, extract and return ONLY the issues list.
Do NOT submit review to GitHub. Do NOT approve PR. Do NOT ask user questions.
Return issues in this exact format:

ISSUES:
- [critical|warning|suggestion] file:line - message
- [critical|warning|suggestion] file:line - message

If no issues found, return: ISSUES: none

Exit immediately after returning issues."
```

Parse subagent output:

- If subagent errors → log error, set codeReview.issues to empty, continue
- Extract issues from ISSUES section (parse severity, file, line, message)
- If "ISSUES: none" → empty issues array

### Test Coverage Check

After code review, verify all new/changed functionality has tests:

1. Identify new functions/components in diff
2. Check for corresponding test files
3. Flag any untested functionality

## Step 4: Print Terminal Summary

After review completes, print summary:

```
═══════════════════════════════════════════════════════════
                    VERIFICATION REPORT
═══════════════════════════════════════════════════════════

Status: ✅ PASS | ❌ FAIL | ⚠️ WARNINGS

Pre-PR Checks:
  Lint:       ✅ | ❌
  Prettier:   ✅ | ❌
  TypeCheck:  ✅ | ❌
  Tests:      ✅ | ❌
  CLAUDE.md:  ✅ | ❌ | N/A

Code Review:
  Critical:   0
  Warnings:   0
  Suggestions: 0

Test Coverage:
  Untested items: 0

Files: X changed (+Y/-Z lines)
═══════════════════════════════════════════════════════════
```

## Rules

- Exit immediately if no changes detected
- Only review changed lines in diff
- Do NOT fix any issues - report only
- Do NOT prompt for action after report
- Exit after report - no further actions
