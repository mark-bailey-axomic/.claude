# CLAUDE.md

- In all interactions and commit messages, be etremely concise and sacrifice grammar for the sake of concision.

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

## Github

- Your primary method for interacting with Github should be the Github CLI (gh).
- NEVER commit directly to protected branches: main, master, develop, development, staging

## Scripts

- Branch creation: always use `~/.claude/scripts/create-branch.sh`
- Worktree creation: always use `~/.claude/scripts/create-worktree.sh`

## Development

- When beginning implementation work, follow workflow skill
- When writing tests, follow testing skill
- When writing TypeScript, follow typescript skill
- When writing React code, follow react skill
- When writing CSS or Sass, follow css-or-sass skill

## Skill Dependencies

- react skill → also invoke typescript, javascript skills
- typescript skill → also invoke javascript skill
- testing skill → invoke language skills based on file type
