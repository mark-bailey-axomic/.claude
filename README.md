# Claude Configuration Repository

Personal Claude AI assistant configuration and workspace for development workflows, commands, and skills.

## Overview

This repository contains customized instructions, commands, and skills for enhancing Claude's capabilities in software development tasks. It serves as a persistent configuration layer that guides Claude's behavior across different development scenarios.

## Structure

### Core Configuration

- **[CLAUDE.md](CLAUDE.md)** - Primary instructions and behavioral guidelines for Claude
- **settings.json** / **settings.local.json** - Configuration settings
- **statusline-command.sh** - Custom status line command
- **task-complete.sh** - Task completion handler

### Commands

Pre-configured workflows in the [commands/](commands/) directory:

- **[code-review.md](commands/code-review.md)** - Review PRs or branch diffs for issues and improvements
- **[create-shred-feedback-tickets.md](commands/create-shred-feedback-tickets.md)** - Create SHRED Jira tickets from Confluence feedback page
- **[fix-merge-conflicts.md](commands/fix-merge-conflicts.md)** - Resolve merge conflicts with AI assistance
- **[jira-ticket.md](commands/jira-ticket.md)** - Fetch and summarize Jira tickets before starting work
- **[pr.md](commands/pr.md)** - Create or modify pull requests following conventions
- **[refine-backlog.md](commands/refine-backlog.md)** - Estimate unestimated Jira backlog tickets using AI analysis with optional codebase inspection
- **[verify-changes.md](commands/verify-changes.md)** - Verify branch changes with code review and pre-PR checks (lint, format, typecheck, tests)

### Scripts

Shell scripts in the [scripts/](scripts/) directory:

- **[create-branch.sh](scripts/create-branch.sh)** - Create Git branches following naming conventions (supports `-c` checkout, `-b` base branch)
- **[create-worktree.sh](scripts/create-worktree.sh)** - Create and switch to Git worktrees for parallel development
- **[clean-worktrees.sh](scripts/clean-worktrees.sh)** - Clean up stale Git worktrees
- **[employee-code.sh](scripts/employee-code.sh)** - Retrieve employee code for branch naming conventions

### Skills

Language and framework-specific best practices in the [skills/](skills/) directory:

- **[css-or-sass/](skills/css-or-sass/)** - CSS and Sass styling guidelines (BEM, nesting, modules, Airbnb standards)
- **[javascript/](skills/javascript/)** - JavaScript coding conventions (ES6+, destructuring, no nested ifs/ternaries, Airbnb standards)
- **[react/](skills/react/)** - React component and hooks guidelines (functional components, hooks, performance, Airbnb standards)
  - **Dependencies:** typescript, javascript
- **[testing/](skills/testing/)** - Testing guidelines and best practices (TDD, AAA pattern, coverage targets)
- **[typescript/](skills/typescript/)** - TypeScript coding guidelines (type safety, strict mode, no all-optional types)
  - **Dependencies:** javascript
- **[workflow/](skills/workflow/)** - Development workflow with TDD/non-TDD paths, branch management, verify-changes integration

## Key Features

- **Concise Communication** - Optimized for brevity, sacrificing grammar for concision
- **Git Integration** - Uses GitHub CLI (`gh`) and Git commands extensively
- **Protected Branch Safety** - Never commits directly to main/master/develop/staging
- **Skill Dependencies** - Automatic skill chaining (e.g., React → TypeScript → JavaScript)
- **Workflow Automation** - Structured commands for common development tasks

## Usage

Claude automatically loads configuration from this directory when initialized. Commands can be invoked by referencing the appropriate markdown file in [commands/](commands/), and skills are automatically applied based on file types and development context.

## Configuration Precedence

1. `settings.local.json` (local overrides, not version controlled)
2. `settings.json` (shared settings)
3. `CLAUDE.md` (base instructions)

## Development Guidelines

- Follow workflow skill for implementation work
- Apply language-specific skills based on file type
- Use commands for repetitive workflows
- Check plans/ for unresolved questions after planning
- Leverage GitHub CLI as primary GitHub interaction method

## Status Line

Custom status line configured via `statusline-command.sh` to display relevant workspace information in Claude's interface.

## Quick Reference

### Invoking Skills

Skills are automatically invoked based on context:

```text
/workflow         - Start implementation work
/testing          - Write tests with TDD
/typescript       - Write TypeScript code
/react            - Write React components
/javascript       - Write JavaScript code
/css-or-sass      - Write CSS/Sass styles
```

### Invoking Commands

Commands handle specific workflows:

```text
/code-review                       - Review current branch
/verify-changes                    - Run pre-PR checks
/pr                                - Create pull request
/jira-ticket [ticket-id]          - Fetch Jira ticket
/refine-backlog                    - Estimate backlog
/fix-merge-conflicts               - Resolve conflicts
/create-shred-feedback-tickets     - Create tickets from Confluence
```

### Using Scripts

Scripts are called directly:

```bash
~/.claude/scripts/create-branch.sh [description] [type] [-c] [-b base]
~/.claude/scripts/create-worktree.sh [branch-name]
~/.claude/scripts/clean-worktrees.sh
~/.claude/scripts/employee-code.sh
```
