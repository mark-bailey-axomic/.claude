# Branch Naming

Format: `{EMPLOYEE_CODE}_{TICKET_ID}_{sanitized-title}_{worktype}`

- **EMPLOYEE_CODE**: injected at session start from `.env`
- **TICKET_ID**: JIRA ticket (e.g., `PROJ-123`)
- **Sanitized title**: lowercase, spaces/special chars to hyphens, max 40 chars, strip trailing hyphens
- **Worktype** derived from JIRA issue type:
  - `bug`/`Bug` → `bug`
  - `defect`/`Defect` → `defect`
  - `technical debt` (case-insensitive) → `debt`
  - anything else → `feature`

Example: `mba_PROJ-123_add-user-auth-endpoint_feature`
