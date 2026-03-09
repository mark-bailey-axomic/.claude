---
name: automate
description: 'Automate the complete workflow of reading a JIRA ticket, creating a branch, planning work via a PRD, implementing changes, committing, creating a PR, self-reviewing, and verifying against ticket requirements. Takes a single required argument: the JIRA issue ID (e.g. PROJ-123).'
---

# Automate

Full lifecycle automation: JIRA ticket → branch → PRD → implementation → PR → review → verified.

**Input:** JIRA issue ID from arguments: `$ARGUMENTS`

---

## Context Budget Rule

Total orchestrator context must stay under 40% of the context window. Delegate all heavy work (file reads, diffs, review details) to sub-agents. The orchestrator tracks only lightweight state: stage, ticket metadata, PRD path, changed file lists, loop counters.

---

## Stage Overview

```
1. Read ticket (sub-agent)
2. Create branch + worktree (orchestrator)
3. Write PRD (sub-agent)
4. Implement + commit tasks (loop: orchestrator + implementer sub-agents)
7. Create PR (orchestrator via /pr skill)
8. Self-review (orchestrator via /review skill + implementer sub-agents)
9. Verify against ticket (verifier sub-agent)
10. Finalize
```

---

## Stage 1: Read Ticket

Spawn a **jira-reader** sub-agent:

- Input: JIRA issue ID
- Actions:
  1. Fetch ticket: `acli jira issue view {TICKET-ID}`
  2. Check labels — if `ai-ready` label is NOT present → **ABORT** with message: "Ticket missing `ai-ready` label. Aborting."
  3. Check assignee:
     - If unassigned → assign to current user: `acli jira issue assign {TICKET-ID} --account-id me`
     - If assigned to current user → proceed
     - If assigned to anyone else → **ABORT** with message: "Ticket assigned to {assignee}. Aborting."
  4. Transition to "In Progress": `acli jira issue transition {TICKET-ID} "In Progress"`
- Return as structured object (orchestrator caches this, never re-fetches):

```json
{
  "id": "PROJ-123",
  "title": "...",
  "description": "...",
  "issueType": "Story|Bug|Task|...",
  "acceptanceCriteria": ["...", "..."],
  "subtasks": ["..."]
}
```

---

## Stage 2: Create Branch & Worktree

The orchestrator handles this directly.

1. Read `EMPLOYEE_CODE` from `.env` in the project root
2. Derive work type from `issueType`:
   - `bug` or `Bug` → `bug`
   - `defect` or `Defect` → `defect`
   - `technical debt` (case-insensitive) → `debt`
   - anything else → `feature`
3. Sanitize ticket title for branch name:
   - lowercase, replace spaces/special chars with hyphens, max 40 chars, strip trailing hyphens
4. Branch name: `{EMPLOYEE_CODE}_{TICKET-ID}_{sanitized-title}_{worktype}`
   - Example: `mba_PROJ-123_add-user-auth-endpoint_feature`
5. Create branch without checking it out: `git branch {branch-name}`
6. Create a git worktree for the new branch (this checks it out in the worktree, not the current working directory):

   ```bash
   git worktree add ../{branch-name} {branch-name}
   ```

7. Store worktree path — all subsequent sub-agents operate within it. The orchestrator's original branch remains checked out.

---

## Stage 3: Write PRD

Spawn a **prd-writer** sub-agent:

- Input: ticket metadata from Stage 1
- Actions: create `prd-{TICKET-ID}.md` in the **worktree root** (not project root)
- PRD format:

```markdown
# PRD: {TICKET-ID} — {title}

## Objective

One paragraph summary of what needs to be achieved.

## Tasks

- [ ] Task 1: <functional goal description>
- [ ] Task 2: <functional goal description>
      ...

## Acceptance Criteria

- AC1
- AC2

## Out of Scope

- ...
```

Tasks must be **functional goals** (e.g. "Add rate limiting to the login endpoint"), NOT code-level diffs (e.g. "Edit line 42 of auth.ts").

- Return: `{ prdPath: "...", taskCount: N }`

---

## Stage 4–6: Implement Tasks (Loop)

Repeat until all PRD tasks are `[x]`:

1. Read PRD, find the next `[ ]` task
2. Spawn an **implementer** sub-agent with a **fresh context**:
   - Input:
     - Single task description
     - Ticket context summary (2–3 sentences: what the ticket is, why this task matters)
     - Worktree path
     - Relevant file paths if known from prior tasks
   - Actions:
     - Explore the codebase to understand structure
     - Implement the task following the coding-guidelines skill if available
     - Do NOT read or modify PRD or review.json
   - Return:

     ```json
     {
       "changedFiles": ["src/foo.ts", "src/bar.ts"],
       "summary": "Added rate limiting middleware and wired it to the login route."
     }
     ```

3. Spawn a **quality-checker** sub-agent:
   - Input: worktree path, changed files from implementer
   - Actions:
     - Run tests (e.g. `npm test`, `pytest`, etc.)
     - Run linter (e.g. `npm run lint`, `eslint`, etc.)
     - Run formatter (e.g. `npm run format:check`, `npx prettier --check`, etc.)
     - If any check fails → fix issues, re-run checks until all pass
   - Return:

     ```json
     {
       "changedFiles": ["src/foo.ts"],
       "summary": "Fixed lint warnings and formatting in foo.ts"
     }
     ```

   - Merge returned `changedFiles` into implementer's `changedFiles`
4. Commit the work (orchestrator):
   - Verify branch name starts with `{EMPLOYEE_CODE}_` or `claude_` — abort if not
   - Stage only the files returned by the implementer + any fix files: `git add <file>` per file
   - **Never** `git add .` or `git add -A`
   - **Never** stage `prd-*.md` or `review.json`
   - Commit message: `{TICKET-ID}: {concise description}` (concise, sacrifice grammar)
5. Mark task `[x]` in PRD
6. Accumulate `changedFiles` in orchestrator state
7. Loop to next `[ ]` task

---

## Stage 7: Create PR

1. Invoke the `/pr` skill with args: `--jira {TICKET-ID} --ai-assisted`
2. Transition JIRA to "In Review": `acli jira issue transition {TICKET-ID} "In Review"`
3. Store the PR URL returned by /pr

---

## Stage 8: Self-Review

1. Invoke the `/review` skill on the current PR
2. If the review returns no issues → proceed to Stage 9
3. If issues found:
   - Write `review.json` in the worktree root (see format below)
   - For each comment in review.json, spawn an **implementer** sub-agent:
     - Input: the specific issue, file path, line number, ticket context
     - Same return format as Stage 4
   - Commit fixes (same rules as Stage 4–6 commits)
   - Delete `review.json`
   - Re-invoke `/review` — repeat up to 3 times
4. After 3 review iterations with persistent issues, surface them to the user and proceed

### review.json format

```json
{
  "event": "REQUEST_CHANGES",
  "body": "Summary of issues found",
  "comments": [
    {
      "path": "src/example.ts",
      "line": 42,
      "body": "Issue description"
    }
  ]
}
```

---

## Stage 9: Verify Against Ticket

Spawn a **verifier** sub-agent:

- Input:
  - Ticket metadata: `{ acceptanceCriteria, description, subtasks }`
  - All changed file paths accumulated across all tasks
  - Worktree path
- Actions: read the changed files, compare implementation against ticket requirements
- Return:

```json
{
  "pass": true,
  "gaps": [
    {
      "requirement": "User should see an error message on failed login",
      "status": "missing",
      "details": "No UI error handling found in LoginForm component"
    }
  ]
}
```

If `pass: false`:

- Mark relevant PRD tasks as `[!]` (needs revision)
- Add new PRD tasks for each gap
- Loop back to Stage 4–6, then 7 (update PR), then 8, then 9 again
- Maximum 2 verification loops — after that, surface gaps to user and proceed

If `pass: true` → proceed to Stage 10

---

## Stage 10: Finalize

1. If any post-PR commits occurred (review fixes or verification gaps):
   - Invoke `/pr` skill with args: `--update --jira {TICKET-ID} --ai-assisted`
2. Output a concise summary:

```
Done.
PR: {PR URL}
Ticket: {TICKET-ID}
Tasks: {N} completed
Review iterations: {N}
Verification: passed
```

---

## Rules Summary

| Rule              | Detail                                             |
| ----------------- | -------------------------------------------------- |
| Context budget    | Orchestrator stays under 40% — delegate heavy work |
| Branch compliance | Always verify branch prefix before committing      |
| Staging           | Explicit `git add <file>` only — never `git add .` |
| Never commit      | `prd-*.md`, `review.json`                          |
| PRD tasks         | Functional goals, not code diffs                   |
| Commits           | One per task, concise message with ticket ID       |
| JIRA ops          | Use `acli`                                         |
| Git/GitHub ops    | Use `gh` CLI where applicable                      |
| Output style      | Extremely concise — sacrifice grammar              |
| Sub-agent returns | Structured summaries only, no raw output           |
