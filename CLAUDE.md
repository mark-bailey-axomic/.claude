# CLAUDE.md

- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Github

- Your primary method for interacting with Github should be the Github CLI (gh).
- NEVER commit directly to protected branches: main, master, develop, development, staging

## Scripts

- Branch creation: always use `~/.claude/scripts/create-branch.sh`
- Worktree creation: always use `~/.claude/scripts/create-worktree.sh`

## Development

- When beginning implementation work, invoke `/workflow`
- When writing tests, invoke `/testing` + language skills based on file type
- When writing TypeScript, invoke `/typescript` (depends on javascript)
- When writing React code, invoke `/react` (depends on typescript, javascript)
- When writing CSS or Sass, invoke `/css-or-sass`
- Always invoke skills via Skill tool before writing code—don't just reference guidelines
