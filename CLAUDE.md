# CLAUDE.md

- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Always Do First

- **Invoke the `frontend-design` skill** before writing any frontend code, every session, no exceptions.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Coding

- Always use TDD: write failing tests first, then implement to make them pass.

## Code Reviews

- When performing code reviews (including /review), always invoke the `/coding-guidelines` skill first.
- Always end review comments with signature: `🤖 Reviewed by [Claude Code](https://claude.com/claude-code)`

## Github

- Your primary method for interacting with Github should be the Github CLI (gh).
- NEVER commit to a branch unless its name starts with `{EMPLOYEE_CODE}_` (from .env) or `claude_`. Always verify current branch before committing.
- Always create worktrees at `~/.claude/worktrees/{repo_name}/{branch_name}`.

## Atlassian

- Your primary method for interacting with Atlassian should be the Atlassian CLI (acli).

## Figma

- Your primary method for interacting with Figma should be the Figma MCP server (local).
