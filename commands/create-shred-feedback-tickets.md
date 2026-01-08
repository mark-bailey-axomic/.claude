---
description: Create SHRED Jira tickets from Confluence Proposal Studio Feedback page entries without tickets
allowed-tools: mcp__atlassian__*, TodoWrite, AskUserQuestion
---

# Create SHRED Feedback Tickets

Create Jira tickets from Proposal Studio Feedback Confluence page for entries without tickets.

## Source

- **Page:** https://axomic.atlassian.net/wiki/spaces/ENP/pages/191004710/Proposal+Studio+Feedback
- **cloudId:** axomic.atlassian.net
- **pageId:** 191004710

## Steps

1. **Read Confluence page**

   Use `mcp__atlassian__getConfluencePage` with cloudId and pageId above

2. **Parse feedback tables**

   - Find rows in main feedback table (NOT "Done" section)
   - Identify rows where Ticket column is empty

3. **Show entries found and confirm**

   Display a numbered table of entries found:

   ```markdown
   ## Entries without tickets found:

   | # | Reporter | Date | Feedback Summary | Priority |
   |---|----------|------|------------------|----------|
   | 1 | PLO | 12/17/2025 | Spinner stops early... | Med |
   | 2 | JMR | 12/02/2025 | TOC sentence case... | Low |
   ```

   Ask user: "Create tickets for all entries above?"
   - Options: "Yes, create all" / "No, let me select" / "Cancel"

4. **If user selects "No, let me select"**

   Use AskUserQuestion with multiSelect: true
   - List all entries as options
   - User selects which ones to create tickets for
   - If user selects none → quit with message "No entries selected. Exiting."

5. **If user selects "Cancel"**

   Quit with message "Cancelled. No tickets created."

6. **Create Jira ticket for each confirmed entry**

   Use `mcp__atlassian__createJiraIssue`:

   ```json
   {
     "cloudId": "axomic.atlassian.net",
     "projectKey": "SHRED",
     "issueTypeName": "Defect",
     "summary": "<concise title from Feedback column>",
     "description": "<full feedback text>",
     "additional_fields": {
       "parent": { "key": "SHRED-2040" },
       "priority": { "id": "<priority_id>" },
       "customfield_10261": [{ "id": "12473" }],
       "customfield_10446": { "id": "10518" }
     }
   }
   ```

7. **Add comments if Conversation column has content**

   Use `mcp__atlassian__addCommentToJiraIssue`:

   ```markdown
   *Migrated from Confluence discussion:*

   **ADE:** <comment text>
   **PLO:** <comment text>
   ```

8. **Return summary table** (do NOT update Confluence page)

   ```markdown
   | Row Description | Ticket Created |
   |-----------------|----------------|
   | <feedback summary> | SHRED-XXXX |
   ```

## Priority Mapping

| Table Value | Priority ID |
|-------------|-------------|
| Low, Post GA Low | 4 |
| Med, GA Med, Post GA Med | 3 |
| High, GA High | 2 |

## Field Reference

| Field | Value |
|-------|-------|
| Project | SHRED |
| Parent | SHRED-2040 |
| Type | Defect |
| Team | Shred Squad 03 (customfield_10261, id: 12473) |
| Technology | Frontend (customfield_10446, id: 10518) |

## Rules

- Skip "Done" section rows
- Skip rows with existing ticket links
- Format comment authors in bold (e.g., **ADE:**, **PLO:**, **JMR:**)
- Do NOT update Confluence page - return summary table instead
