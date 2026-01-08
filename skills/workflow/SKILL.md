---
name: workflow
description: Development workflow with TDD/non-TDD paths. Use when starting implementation work on features or bug fixes.
---

# Workflow

Development workflow with conditional TDD/non-TDD paths.

## Protected Branches

Never commit directly to: `main`, `master`, `develop`, `development`, `staging`

## Pre-checks

1. **Branch check**

   ```bash
   git branch --show-current
   ```

   - If on protected branch → need branch creation (step 1)
   - If on feature branch → ask if correct branch
     - No → ask: branch off current or staging? → need branch creation (step 1)
     - Yes → skip branch creation, check worktree (step 2)

2. **Worktree check** (only if on correct branch)

   ```bash
   git rev-parse --show-toplevel | grep -q '/worktrees/'
   ```

   - In worktree → skip worktree creation
   - Not in worktree → need worktree creation (step 2)

3. **Ask:** TDD approach? (yes/no)

## Steps (TDD)

1. Create branch (skip if on correct branch)

   ```bash
   ~/.claude/scripts/create-branch.sh [ticket-id] [description] [type]
   ```

2. Create worktree (skip if already in worktree)

   ```bash
   ~/.claude/scripts/create-worktree.sh [branch-name]
   ```

3. **Red-Green-Refactor cycle** (repeat until feature complete):

   a. **Red:** Write test(s) for next piece of functionality

   b. **Red:** Run tests — verify new test(s) FAIL

   c. **Green:** Implement minimal code to pass

   d. **Green:** Run tests — verify all PASS

   e. **Refactor:** Clean up code if needed — tests must still pass

4. Final test run — all tests must pass

5. Pre-PR checks — fix all failures:

   - Lint
   - Prettier
   - TypeCheck
   - CLAUDE.md compliance

6. Create PR via `/pr`

7. Update Jira status via MCP (if ticket exists)
   - Use `mcp__atlassian__*` tools to set status to "In Review"

## Steps (non-TDD)

1. Create branch (skip if on correct branch)

   ```bash
   ~/.claude/scripts/create-branch.sh [ticket-id] [description] [type]
   ```

2. Create worktree (skip if already in worktree)

   ```bash
   ~/.claude/scripts/create-worktree.sh [branch-name]
   ```

3. Implement

4. Run tests — fix all failures before proceeding

5. Pre-PR checks — fix all failures:

   - Lint
   - Prettier
   - TypeCheck
   - CLAUDE.md compliance

6. Create PR via `/pr`

7. Update Jira status via MCP (if ticket exists)
   - Use `mcp__atlassian__*` tools to set status to "In Review"

## Rules

- NEVER commit to protected branches (main, master, develop, development, staging)
- Tests must pass before PR
- All checks must pass before PR
- Code must comply with project CLAUDE.md
- Works standalone or after `/jira-ticket`
- Always use Atlassian MCP for Jira operations
