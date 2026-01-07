---
description: Create git branch following naming conventions
allowed-tools: Bash(git:*), Bash(gh:*), SlashCommand, AskUserQuestion
argument-hint: [ticket-id] [description] [type]
---

# Create a New Branch

Create a git branch following project conventions.

## Steps

1. **Check current branch**

   ```bash
   git branch --show-current
   ```

2. **Determine base branch**

   - If on `staging` or `develop` → use current branch as base
   - If on `master` or `main` → switch to `staging` first
   - Otherwise → ask user which branch to base from

3. **Get branch details from user** (if not provided)

   - Ticket ID (e.g. `ABC-123`)
   - Branch type: `feature`, `bug`, `defect`, `chore`, `hotfix`, `spike`, `debt`
   - Brief description (kebab-case)

4. **Create branch**

   - Get employee code via `/employee-code`
   - Format: `{employee-code}_{ticket-id}_{description}_{type}`
   - Example: `jdo_ABC-123_fix-login-validation_bug`
   - No ticket: `{employee-code}_{description}_{type}`

5. **Run commands**

   ```bash
   git fetch origin
   git checkout -b {branch-name} origin/{base-branch}
   ```

## Naming Rules

- Prefix: `{employee-code}_` (get via `/employee-code`)
- Ticket ID after prefix if available (e.g. `_ABC-123_`)
- Suffix by type: `_feature`, `_bug`, `_defect`, `_chore`, `_hotfix`, `_spike`, `_debt`
- Keep names brief, lowercase, hyphens only
- No spaces or special characters

## Examples

| Ticket                     | Type    | Branch Name                                        |
| -------------------------- | ------- | -------------------------------------------------- |
| ABC-123 "Fix login bug"    | bug     | `{employee-code}_ABC-123_fix-login-bug_bug`        |
| DEF-456 "Add user profile" | feature | `{employee-code}_DEF-456_add-user-profile_feature` |
| No ticket, refactor auth   | chore   | `{employee-code}_refactor-auth_chore`              |
