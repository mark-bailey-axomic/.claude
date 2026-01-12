---
description: Estimate unestimated backlog tickets using AI analysis
allowed-tools: mcp__atlassian__*, Task, TodoWrite, AskUserQuestion, Bash, Glob, Grep, Read
argument-hint: <project-key> <board-id> [--team "Team Name"] [--technology Frontend|Backend] [--codebase]
---

# Refine Backlog

Estimate unestimated tickets using parallel AI analysis. Uses "Story Points" for stories/tasks and "Bug / Defect Estimate" for bugs/defects.

**Project:** $1
**Board:** $2

Reference URL format: `/projects/$1/boards/$2`

## Options

Parse flags from arguments:

- `--team <value>`: Filter by Team() field (e.g. "Shred Squad 03")
- `--technology <value>`: Filter by Technology field (Frontend, Backend)
- `--codebase`: Enable codebase analysis for more accurate estimates (requires running in git repo)

## Steps

### 0. Pre-flight Check (if --codebase)

If `--codebase` flag is provided:

1. Check if current directory is a git repo: `git rev-parse --is-inside-work-tree`
2. If not a git repo, warn user and ask if they want to continue without codebase analysis
3. Store working directory path for subagent prompts

### 1. Get CloudId

Use `mcp__atlassian__getAccessibleAtlassianResources` to find available Jira instances.
Use first available cloudId for subsequent calls.

### 2. Discover Estimate Fields

Use `mcp__atlassian__getJiraProjectIssueTypesMetadata`:

- cloudId: {from step 1}
- projectIdOrKey: $1

Search returned fields for:

1. **Story Points field**: name containing "story" and "point" (case insensitive) → store as `story_points_field`
2. **Bug/Defect Estimate field**: name containing "bug" or "defect" and "estimate" (case insensitive) → store as `bug_estimate_field`

If Story Points not found, use AskUserQuestion: "Story points field not found. Enter customfield ID:"
If Bug Estimate not found, use AskUserQuestion: "Bug/Defect estimate field not found. Enter customfield ID:"

### 3. Query Unestimated Tickets

**Base JQL** (unestimated, not started tickets):

```
project = $1 AND statusCategory = "To Do" AND (
  (type IN (Bug, Defect) AND "Bug / Defect Estimate" IS EMPTY)
  OR (type NOT IN (Bug, Defect) AND "Story Points" IS EMPTY)
) ORDER BY Rank ASC
```

**If --team flag provided**, append to JQL (before ORDER BY):

```
AND "team()[select list (multiple choices)]" = "{value}"
```

**If --technology flag provided**, append to JQL (before ORDER BY):

```
AND Technology = "{value}"
```

Use `mcp__atlassian__searchJiraIssuesUsingJql` with fields: `["key", "summary", "description", "status", "issuetype", "priority", "comment"]`

Note: Board ID ($2) used for reference. JQL queries by project since boards are project-scoped.
Note: Bug/Defect tickets use "Bug / Defect Estimate" field; all other types use "Story Points" field.

**Guardrails:**

- 0 results: Report "No unestimated tickets found in $1 board $2" and STOP
- > 20 results: Use AskUserQuestion "Found {n} unestimated tickets. Proceed with estimation?"
- > 50 results: Warn "Large backlog. Consider filtering further."

### 4. Spawn Parallel Estimators

Create todo list tracking each ticket.

For each ticket (max 10 parallel per batch), spawn Task:

**Without --codebase flag:**

```
subagent_type: general-purpose
model: haiku
prompt: |
  Estimate story points for Jira ticket.

  **Ticket:** {KEY}
  **CloudId:** {cloudId}

  ## Instructions

  1. Fetch ticket via `mcp__atlassian__getJiraIssue` with issueIdOrKey: {KEY}
  2. Review: summary, description, acceptance criteria
  3. Check linked issues via `mcp__atlassian__getJiraIssueRemoteIssueLinks`
  4. Estimate using Fibonacci scale

  ## Estimation Guide

  | Points | Scope |
  |--------|-------|
  | 1 | Trivial, <1hr, single file |
  | 2 | Simple, 1-2hr, isolated change |
  | 3 | Small, half day, few files |
  | 5 | Medium, 1 day, multiple components |
  | 8 | Large, 2-3 days, cross-cutting |
  | 13 | Very large, ~1 week |
  | 21 | Epic-sized, should be broken down |

  ## Output (JSON only)

  {"key": "{KEY}", "estimate": N, "confidence": "high|medium|low", "reasoning": "brief explanation"}
```

**With --codebase flag (run in git repo):**

```
subagent_type: general-purpose
model: haiku
prompt: |
  Estimate story points for Jira ticket with codebase analysis.

  **Ticket:** {KEY}
  **CloudId:** {cloudId}
  **Working Directory:** {cwd}

  ## Instructions

  1. Fetch ticket via `mcp__atlassian__getJiraIssue` with issueIdOrKey: {KEY}
  2. Review: summary, description, acceptance criteria
  3. Check linked issues via `mcp__atlassian__getJiraIssueRemoteIssueLinks`
  4. **Codebase Analysis:**
     - Extract keywords from ticket (component names, file names, feature areas)
     - Use Grep to search for relevant code patterns
     - Use Glob to find related files (e.g. `**/*{keyword}*`)
     - Count files that would likely need changes
     - Check for existing similar implementations or patterns
     - Assess test coverage requirements (look for test files)
  5. Estimate using Fibonacci scale, informed by code complexity

  ## Estimation Guide

  | Points | Scope |
  |--------|-------|
  | 1 | Trivial, <1hr, single file |
  | 2 | Simple, 1-2hr, isolated change |
  | 3 | Small, half day, few files |
  | 5 | Medium, 1 day, multiple components |
  | 8 | Large, 2-3 days, cross-cutting |
  | 13 | Very large, ~1 week |
  | 21 | Epic-sized, should be broken down |

  ## Output (JSON only)

  {"key": "{KEY}", "estimate": N, "confidence": "high|medium|low", "reasoning": "brief explanation", "files_affected": N, "codebase_notes": "what you found"}
```

Wait for batch completion, then process next batch.
Collect all results. On subagent failure, note ticket as "failed" and continue.

### 5. Aggregate Results

Build summary table:

**Without --codebase:**

```markdown
## Estimation Results

| #   | Ticket | Type  | Summary | Est | Conf | Reasoning |
| --- | ------ | ----- | ------- | --- | ---- | --------- |
| 1   | KEY-1  | Story | ...     | 3   | high | ...       |
| 2   | KEY-2  | Bug   | ...     | 2   | med  | ...       |
```

**With --codebase:**

```markdown
## Estimation Results

| #   | Ticket | Type  | Summary | Est | Conf | Files | Reasoning |
| --- | ------ | ----- | ------- | --- | ---- | ----- | --------- |
| 1   | KEY-1  | Story | ...     | 3   | high | 3     | ...       |
| 2   | KEY-2  | Bug   | ...     | 2   | med  | 1     | ...       |
```

For any 21pt estimates, append: " [should be broken down]"

Add distribution summary:

```
Total: N tickets | Distribution: 1pt(x) 2pt(x) 3pt(x) 5pt(x) 8pt(x) 13pt(x) 21pt(x)
```

If --codebase was used, add note:

```
Estimates informed by codebase analysis in {cwd}
```

Report any failed estimations.

### 6. User Selection

Use AskUserQuestion with multiSelect: true

Build options from results:

- Each ticket: "{KEY}: {estimate} pts - {reasoning truncated to 50 chars}"

Question: "Select tickets to update with estimated story points:"

If user selects none or cancels, report "No tickets updated" and STOP.

### 7. Update Selected Tickets

For each selected ticket, determine which field to update based on issue type:

**If ticket type is Bug or Defect:**

```
mcp__atlassian__editJiraIssue:
  cloudId: {cloudId}
  issueIdOrKey: {key}
  fields:
    {bug_estimate_field}: {estimate}
```

**If ticket type is NOT Bug or Defect:**

```
mcp__atlassian__editJiraIssue:
  cloudId: {cloudId}
  issueIdOrKey: {key}
  fields:
    {story_points_field}: {estimate}
```

Track success/failure per ticket.

### 8. Final Report

```markdown
## Update Results

| Ticket | Type  | Field          | Estimate | Status                    |
| ------ | ----- | -------------- | -------- | ------------------------- |
| KEY-1  | Story | Story Points   | 3        | Updated                   |
| KEY-2  | Bug   | Bug/Defect Est | 2        | Updated                   |
| KEY-3  | Task  | Story Points   | 5        | Failed: permission denied |

Successfully updated: X of Y tickets
```

## Rules

- Never update tickets without explicit user selection
- Continue estimation even if individual tickets fail
- Use Fibonacci scale only: 1, 2, 3, 5, 8, 13, 21
- Flag 21pt estimates as needing breakdown
- Max 10 parallel subagents per batch
- Estimates assume human developer effort, not AI
- With --codebase: estimates are informed by actual code complexity
- Without --codebase: estimates based on ticket description only (less accurate)
- Bug/Defect tickets: update "Bug / Defect Estimate" field
- All other types (Story, Task, Spike, etc.): update "Story Points" field
