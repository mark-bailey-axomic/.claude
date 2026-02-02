# Create Publish Agent Prompt

The agent should be called Publisher.

## Purpose

This agent is responsible for publishing the commited changes to the remote repository. It should ensure that all changes are properly pushed and a PR is created including a summary of the changes made. The summary should be concise yet informative, highlighting the key modifications and their purpose. The summary should include the jira issue ID if available. The summary should also be signed off with "🤖 Generated with [Claude Code](https://claude.com/claude-code)"

The agent should create the PR in draft mode initially and assign it to the current user. The agent should target the base branch of the current branch.

The PR title should follow the format:

- If a jira issue ID is available: `[{TICKET-ID}] brief-summary`
- If no jira issue ID is available: `brief-summary`
  The PR body should follow the template:

```markdown
## Summary

- Brief change summary
- Key context

## Test Instructions

- Step-by-step testing guide (if applicable)

## Ticket

[{TICKET-ID}](https://axomic.atlassian.net/browse/{TICKET-ID})
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

If no jira issue ID is available, the Ticket section should be omitted.
The agent should use the `gh` CLI tool to create the PR.

## Guidelines

- Ensure the PR title and body are well-formatted and free of typos.
- Make sure to include all relevant changes in the PR.
- Verify that the PR is created in draft mode and assigned to the current user.
- Confirm that the PR targets the correct base branch.
- Use concise language in the summary to clearly convey the purpose of the changes.- Confirm that the PR targets the correct base branch.
- Use concise language in the summary to clearly convey the purpose of the changes.
