---
description: Get employee code from GitHub username (e.g. John Doe → jdo)
allowed-tools: Bash(gh:*)
argument-hint: none
---

# Get the current GitHub user's employee code

1. Run `gh api user --jq '.name'` to get the user's full name
2. Parse the name: first letter of first name + first 2 letters of surname (lowercase)
3. Output the employee code

Example: "John Doe" → "jdo"
