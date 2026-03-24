---
name: address-feedback
description: Address PR review feedback end-to-end. Fetches PR comments, opens worktree, spawns agents to address valid feedback, reacts/replies to each comment, pushes and re-requests review. Takes optional PR number/URL, --reviewer filter, --dry-run flag, --include-bots flag.
---

# Address Feedback

Automate PR review feedback: fetch comments -> classify -> address -> react/reply -> push.

**Input:** `$ARGUMENTS` — PR number, URL, or empty (auto-detect from branch). Optional `--reviewer <user>` filter, `--dry-run` flag, `--include-bots` flag.

---

## Context Budget Rule

Total orchestrator context must stay under 40% of the context window. Delegate all heavy work (file reads, diffs, comment analysis, code changes) to sub-agents. The orchestrator tracks only lightweight state: stage, PR metadata, comment classifications, changed file lists, loop counters.

---

## Stage Overview

```
1. Resolve PR + gather metadata (orchestrator)
2. Fetch & classify comments (sub-agent)
2.5. Enrich Confluence-linked comments (parallel sub-agents)
3. Open worktree (orchestrator)
3.5. Load coding guidelines (orchestrator — invoke /coding-guidelines once, cache output)
4. Address comments (parallel implementer sub-agents, grouped by file)
5. Self-review (orchestrator via /review skill + implementer sub-agents)
6. React & reply to comments (orchestrator)
7. Push + update PR + re-request review (orchestrator)
8. Cleanup + report (orchestrator)
```

---

## Stage 1: Resolve PR & Gather Metadata

Orchestrator parses flags from `$ARGUMENTS`:

- Extract `--reviewer <user>` if present
- Extract `--dry-run` if present
- Extract `--include-bots` if present
- Remaining argument is PR number/URL (or empty for auto-detect)

Then gather metadata:

```bash
# If no PR arg, auto-detect from current branch
gh pr view {PR_ARG} --json number,headRefName,baseRefName,url,author,reviewRequests

# Get repo info
gh repo view --json owner,name
```

- Read `EMPLOYEE_CODE` from `.env` in the user-level Claude directory (`~/.claude/.env`)
- **Branch safety**: verify `headRefName` starts with `{EMPLOYEE_CODE}_` or `claude_`. Abort if not.
- **Label guard**: check `gh pr view {PR_ARG} --json labels -q '.labels[].name'`. If `agent-ignore` is present, abort with: `"PR has agent-ignore label — aborting."`

---

## Stage 2: Fetch & Classify Comments

Spawn a **comment-classifier** sub-agent:

- Input: owner, repo name, PR number, PR author login, `--reviewer` filter (if set)
- Actions:
  1. Fetch review threads via GraphQL (includes resolution status):

     ```bash
     gh api graphql -f query='
       query($owner: String!, $repo: String!, $pr: Int!) {
         repository(owner: $owner, name: $repo) {
           pullRequest(number: $pr) {
             reviewThreads(first: 100) {
               nodes {
                 isResolved
                 comments(first: 50) {
                   nodes {
                     id
                     databaseId
                     path
                     line
                     body
                     author { login }
                     replyTo { databaseId }
                   }
                 }
               }
             }
           }
         }
       }' -f owner={owner} -f repo={repo} -F pr={prNumber}
     ```

  2. Fetch reviews (includes review body comments): `gh api repos/{owner}/{repo}/pulls/{prNumber}/reviews --paginate`
     - Reviews with non-empty `body` and `state` of `CHANGES_REQUESTED` or `COMMENTED` are **review-level comments** — classify these alongside thread comments
     - `commentType` for these is `"review_body"`; they have no `path`/`line`
  3. Fetch issue comments: `gh api repos/{owner}/{repo}/issues/{prNumber}/comments --paginate`
  4. Skip resolved threads (`isResolved == true`) — classify as **resolved**
  5. Unless `--include-bots` is set, skip bot comments (author `type == "Bot"` or login ending in `[bot]`)
  6. Skip PR author self-comments (author login == PR author login)
  7. Apply `--reviewer` filter if set (only keep comments from that user)
  8. Group threaded comments via `replyTo` / `in_reply_to_id` — classify root only, replies are context
  9. Classify each root comment:
     - **addressable** — requests a concrete code change. Either: (a) has `path` and actionable line-level feedback, or (b) is a `review_body` with actionable PR-level feedback (e.g. missing features, required changes)
     - **non-addressable** — question, praise, architectural disagreement w/ no clear action
     - **outdated** — `position == null` on review comments (GitHub marks these when code has changed)
- Return:

```json
{
  "addressable": [
    {
      "id": 123,
      "path": "src/foo.ts",
      "line": 42,
      "body": "...",
      "author": "reviewer-login",
      "thread": ["reply1 body", "reply2 body"],
      "commentType": "review_comment",
      "confluenceLinks": ["https://instance.atlassian.net/wiki/spaces/SPACE/pages/123/Title"]
    },
    {
      "id": 456,
      "path": null,
      "line": null,
      "body": "This PR should also include...",
      "author": "reviewer-login",
      "thread": [],
      "commentType": "review_body",
      "confluenceLinks": ["https://instance.atlassian.net/wiki/spaces/SPACE/pages/789/Plan"]
    }
  ],
  "nonAddressable": [
    {
      "id": 456,
      "body": "...",
      "author": "reviewer-login",
      "reason": "question — no code change requested",
      "commentType": "review_comment|issue_comment"
    }
  ],
  "outdated": [
    {
      "id": 789,
      "body": "...",
      "author": "reviewer-login",
      "commentType": "review_comment"
    }
  ],
  "resolved": [
    {
      "id": 101,
      "body": "...",
      "author": "reviewer-login",
      "commentType": "review_comment"
    }
  ],
  "reviewers": ["reviewer1", "reviewer2"]
}
```

If `--dry-run`, print a classification table and **STOP**:

```
Addressable: {N}
  - #{id} ({path}:{line}) — {first 60 chars of body}        (review_comment)
  - #{id} (review body) — {first 60 chars of body}           (review_body)
Non-addressable: {N}
  - #{id} — {reason}
Outdated: {N}
  - #{id} — {first 60 chars of body}
Resolved: {N} (skipped)
  - #{id} — {first 60 chars of body}
```

---

## Stage 2.5: Enrich Confluence-linked Comments

After classification, orchestrator scans all addressable comment bodies + threads for Confluence URLs matching:

```
https://{instance}.atlassian.net/wiki/spaces/{space}/pages/{pageId}/{title}
```

If none found, skip to Stage 3.

For each **unique** Confluence page found, spawn a **confluence-reader** sub-agent in parallel:

- Input: page URL, the comment(s) referencing it
- Actions:
  1. Extract `pageId` from URL
  2. Fetch page content via Confluence REST API (acli preferred, curl fallback):

     ```bash
     # Using acli (preferred)
     acli confluence --action getPageSource --id {pageId} --outputFormat markdown
     # Fallback: curl with Confluence REST API v2
     curl -s -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
       "https://{instance}.atlassian.net/wiki/api/v2/pages/{pageId}?body-format=atlas_doc_format" \
       | jq -r '.body.atlas_doc_format.value'
     ```

  3. Summarize only sections relevant to the referencing comment(s) — keep under 500 words per page
- Return:

```json
{
  "pageUrl": "https://...",
  "pageTitle": "...",
  "relevantContext": "Summarized content relevant to the comment..."
}
```

Orchestrator attaches `confluenceContext` (array of `{ pageUrl, pageTitle, relevantContext }`) to each enriched addressable comment before passing to Stage 4.

---

## Stage 3: Open Worktree

```bash
git fetch origin {branchName}
REPO_NAME=$(gh repo view --json name -q .name)
git worktree add ~/.claude/worktrees/${REPO_NAME}/{branchName} origin/{branchName}
```

Store worktree path for all subsequent stages.

---

## Stage 3.5: Load Coding Guidelines

Invoke `/coding-guidelines` once, cache output as `codingGuidelines` for all sub-agents.

---

## Stage 4: Address Comments (Parallel)

Group addressable comments by file. Spawn **multiple implementer sub-agents in parallel** — one per file-group (or batch of related files).

Each **implementer** sub-agent (fresh context):

- Input:
  - Comments for its file(s) (id, path, line, body, thread context)
  - `confluenceContext` per comment (if enriched in Stage 2.5)
  - Worktree path
  - `codingGuidelines` from Stage 3.5
  - PR context (base branch, what the PR does)
- Actions:
  - Read the relevant file(s)
  - For `review_body` comments (no `path`): use the PR diff, comment body, and `confluenceContext` to determine which files need changes. Search the codebase as needed.
  - Address each comment's feedback
  - If a comment implies behavior change, follow TDD (write failing test first, then implement)
  - If the implementer disagrees with a comment, it may reject it with a reason
  - Do NOT read or modify `review.json`
- Return:

```json
{
  "addressed": [
    { "commentId": 123, "summary": "Renamed variable for clarity" }
  ],
  "rejected": [
    { "commentId": 456, "reason": "Current approach is more performant because..." }
  ],
  "changedFiles": ["src/foo.ts", "src/foo.test.ts"]
}
```

After all implementers complete, spawn a single **quality-checker** sub-agent:

- Input: all changedFiles from all implementers, worktree path
- Actions: run tests, linter, formatter; fix if needed
- Return: `{ changedFiles: [...], summary: "..." }`

Commit (orchestrator):

- Verify branch name starts with `{EMPLOYEE_CODE}_` or `claude_` — abort if not
- Stage only changed files: `git add <file>` per file (never `git add .`)
- Never stage `review.json`
- Commit message: `address feedback: {concise summary}`
- One commit for all changes

---

## Stage 5: Self-Review

Same pattern as implement Stage 8:

1. Invoke `/review` skill on the current PR
2. If no issues -> proceed to Stage 6
3. If issues found:
   - Write `review.json` in worktree root
   - For each issue, spawn **implementer** sub-agent (input: issue, file path, line, `codingGuidelines`)
   - Commit fixes (same staging/naming rules, message: `address feedback: fix review issue`)
   - Delete `review.json`
   - Re-invoke `/review` — repeat up to 3 times
4. After 3 iterations with persistent issues, surface to user and proceed

### review.json format

```json
{
  "event": "REQUEST_CHANGES",
  "body": "Summary of issues found",
  "comments": [
    {
      "path": "src/example.ts",
      "line": 42,
      "body": "Issue description"
    }
  ]
}
```

---

## Stage 6: React & Reply

Orchestrator handles all reactions and replies. Merge addressed/rejected results from all implementer sub-agents.

| Category | Reaction | Reply |
| --- | --- | --- |
| Addressed | +1 on comment | "Addressed: {summary}" as threaded reply |
| Rejected | eyes on comment | "Not addressed: {reason}" as threaded reply |
| Non-addressable | none | "Not addressed: {reason}" as threaded reply |
| Outdated | none | "Skipped: outdated. Re-request if still relevant." |

**gh CLI commands for review comments:**

```bash
# Reaction on review comment
gh api repos/{owner}/{repo}/pulls/comments/{commentId}/reactions -f content="+1"
gh api repos/{owner}/{repo}/pulls/comments/{commentId}/reactions -f content="eyes"

# Reply to review comment (threaded)
gh api repos/{owner}/{repo}/pulls/{prNumber}/comments -f body="..." -f in_reply_to={commentId}
```

**gh CLI commands for issue comments:**

```bash
# Reaction on issue comment
gh api repos/{owner}/{repo}/issues/comments/{commentId}/reactions -f content="+1"
gh api repos/{owner}/{repo}/issues/comments/{commentId}/reactions -f content="eyes"
```

For non-addressable issue comments and outdated comments, reply using:

```bash
# Issue comment reply (new issue comment referencing the original)
gh api repos/{owner}/{repo}/issues/{prNumber}/comments -f body="> {quote first line of original}\n\n{reply}"
```

---

## Stage 7: Push & Update PR + Re-request Review

```bash
# Push from worktree
git -C {worktreePath} push origin {branchName}
```

- Invoke `/pr` skill with args: `--update` to append feedback-addressed summary
- Re-request review from all original reviewers:

```bash
gh pr edit {prUrl} --add-reviewer {reviewer1},{reviewer2}
```

Use the `reviewers` list from Stage 2's classification output.

---

## Stage 8: Cleanup & Report

- Remove worktree: `git worktree remove ~/.claude/worktrees/${REPO_NAME}/{branchName}`
- Output summary:

```
Done.
PR: {prUrl}
Addressed: {N} (+1 + reply)
Rejected: {R} (eyes + reply)
Skipped: {M} (replied with reason)
Outdated: {O}
Resolved: {V} (skipped)
Commits: {C}
```

---

## Rules Summary

| Rule | Detail |
| --- | --- |
| Context budget | Orchestrator stays under 40% — delegate heavy work |
| Branch compliance | Always verify branch prefix before committing |
| Staging | Explicit `git add <file>` only — never `git add .` |
| TDD | Tests first when comment implies behavior change |
| Reactions | +1 addressed, eyes rejected |
| Replies | Always reply — addressed or not |
| Coding guidelines | Load once, pass to all implementers |
| Never commit | `review.json` |
| Parallelism | Spawn implementers in parallel per file-group |
| Re-request review | Auto re-request after push |
| Output style | Extremely concise — sacrifice grammar |
| Resolved threads | Skip — don't address or reply |
| Sub-agent returns | Structured summaries only, no raw output |
