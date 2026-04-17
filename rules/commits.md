# Commits

Format: `{TICKET-ID}: {concise description}`

- For feedback addresses: `address feedback: {concise summary}`

## Branch Safety

- **NEVER** commit unless current branch starts with `{EMPLOYEE_CODE}_` or `claude_`
- Always run `git rev-parse --abbrev-ref HEAD` and verify before committing

## Staging

- **Explicit per-file only**: `git add <file1> <file2>`
- **NEVER** use `git add .` or `git add -A`
- **NEVER** stage: `prd-*.md`, `review.json`, `package-lock.json`
