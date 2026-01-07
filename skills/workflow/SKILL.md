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

   - If on protected branch → MUST create feature branch first
   - If on feature branch → ask if correct branch
     - Yes → skip branch/worktree creation
     - No → ask: branch off current or staging?

2. **Ask:** TDD approach? (yes/no)

## Steps (TDD)

1. Create branch/worktree (skip if on correct branch)

   - Run `/create-branch` with ticket ID and description
   - Run `/create-worktree` for the new branch

2. Write tests first

3. Implement to pass tests

4. Run tests — fix all failures before proceeding

5. Pre-PR checks — fix all failures:

   - Lint
   - Prettier
   - TypeCheck
   - CLAUDE.md compliance

6. Create PR via `/pr`

7. Update Jira status via MCP (if ticket exists)
   - Use `mcp__atlassian__*` tools to set status to "In Review"

## Steps (non-TDD)

1. Create branch/worktree (skip if on correct branch)

   - Run `/create-branch` with ticket ID and description
   - Run `/create-worktree` for the new branch

2. Implement

3. Run tests — fix all failures before proceeding

4. Pre-PR checks — fix all failures:

   - Lint
   - Prettier
   - TypeCheck
   - CLAUDE.md compliance

5. Create PR via `/pr`

6. Update Jira status via MCP (if ticket exists)
   - Use `mcp__atlassian__*` tools to set status to "In Review"

## Rules

- NEVER commit to protected branches (main, master, develop, development, staging)
- Tests must pass before PR
- All checks must pass before PR
- Code must comply with project CLAUDE.md
- Works standalone or after `/jira-ticket`
- Always use Atlassian MCP for Jira operations
