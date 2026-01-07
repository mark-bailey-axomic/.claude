---
description: Fetch and summarize Jira ticket before starting work
allowed-tools: mcp__atlassian__*, AskUserQuestion, Skill, TodoWrite
argument-hint: <ticket-id>
---

# Read JIRA Ticket

Fetch and understand JIRA ticket before starting work.

**Ticket ID:** $ARGUMENTS

## Steps

1. **Fetch ticket details** using Atlassian MCP server

   Use `mcp__atlassian__searchJiraIssuesUsingJql` with JQL: `key = $ARGUMENTS`

2. **Read and understand** the ticket requirements

3. **Ask clarifying questions** if anything unclear

4. **Summarize proposed solution** (concise)

5. **Wait for approval** — do NOT begin work until told

6. **When told to begin** — validate assignment and status first

   a. **Get current user** via `mcp__atlassian__atlassianUserInfo`

   b. **Check ticket assignee:**
      - If unassigned → assign to self via `mcp__atlassian__editJiraIssue`
      - If assigned to self → proceed
      - If assigned to someone else → report "Ticket assigned to [name]" and **STOP** (do not continue)

   c. **Check ticket status:**
      - If not "In Progress" → get transitions via `mcp__atlassian__getTransitionsForJiraIssue`, then transition to "In Progress" via `mcp__atlassian__transitionJiraIssue`

   d. **Follow workflow skill** with ticket context ($ARGUMENTS)

## Ticket URL Format

`https://axomic.atlassian.net/browse/$ARGUMENTS`

## Status Flow

| Action              | Set Status To |
| ------------------- | ------------- |
| PR ready for review | In Review     |
| Making changes      | In Progress   |
| Ready again         | In Review     |

## Rules

- Always fetch ticket before starting work
- Ask questions to clarify requirements
- Summarize solution concisely before implementation
- Never begin work without explicit approval
