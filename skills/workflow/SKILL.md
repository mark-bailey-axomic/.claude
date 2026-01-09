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
     - No → need branch creation (use `-b current` to branch off current)
     - Yes → skip branch creation, proceed to step 2

2. **Ask:** Use worktree or checkout-only?
   - Worktree → proceed to worktree check (step 3)
   - Checkout-only → use `-c` flag, skip worktree check and step 2

3. **Worktree check** (only if using worktree flow AND on correct branch)

   ```bash
   [ -f "$(git rev-parse --git-dir)" ]
   ```

   - Returns true (in linked worktree) → skip worktree creation
   - Returns false (main repo) → need worktree creation (step 2)

4. **Ask:** TDD approach? (yes/no)

## Steps (TDD)

1. Create branch (skip if on correct branch)

   ```bash
   ~/.claude/scripts/create-branch.sh [description] [type] [-c] [-b <base>]
   ```

   - Include ticket ID in description if needed (e.g., `SHRED-123-my-feature`)
   - `-b current` to branch off current branch, `-b <name>` for other base (default: staging)
   - `-c` to checkout (use for checkout-only flow, skip if using worktree)
   - Script outputs the created branch name for use in step 2

2. Create worktree (skip if checkout-only or already in worktree)

   ```bash
   ~/.claude/scripts/create-worktree.sh [branch-name-from-step-1]
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
   ~/.claude/scripts/create-branch.sh [description] [type] [-c] [-b <base>]
   ```

   - Include ticket ID in description if needed (e.g., `SHRED-123-my-feature`)
   - `-b current` to branch off current branch, `-b <name>` for other base (default: staging)
   - `-c` to checkout (use for checkout-only flow, skip if using worktree)
   - Script outputs the created branch name for use in step 2

2. Create worktree (skip if checkout-only or already in worktree)

   ```bash
   ~/.claude/scripts/create-worktree.sh [branch-name-from-step-1]
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
