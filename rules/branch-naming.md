# Branch Naming

Format: `{EMPLOYEE_CODE}_{TICKET_ID}_{sanitized-title}_{worktype}`

- **EMPLOYEE_CODE**: from `.env` (e.g., `mba`)
- **TICKET_ID**: JIRA ticket (e.g., `PROJ-123`)
- **Sanitized title**: lowercase, spaces/special chars to hyphens, max 40 chars, strip trailing hyphens
- **Worktype** derived from JIRA issue type:
  - `bug`/`Bug` → `bug`
  - `defect`/`Defect` → `defect`
  - `technical debt` (case-insensitive) → `debt`
  - anything else → `feature`

Example: `mba_PROJ-123_add-user-auth-endpoint_feature`

## Branch Safety

- **NEVER** commit unless current branch starts with `{EMPLOYEE_CODE}_` or `claude_`
- Always run `git rev-parse --abbrev-ref HEAD` and verify before committing
