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
- **[fix-merge-conflicts.md](commands/fix-merge-conflicts.md)** - Resolve merge conflicts
- **[jira-ticket.md](commands/jira-ticket.md)** - JIRA ticket management
- **[pr.md](commands/pr.md)** - Pull request creation and management
- **[refine-backlog.md](commands/refine-backlog.md)** - Estimate unestimated Jira backlog tickets using AI analysis with optional codebase inspection

### Scripts

Shell scripts in the [scripts/](scripts/) directory:

- **create-branch.sh** - Create Git branches following naming conventions
- **create-worktree.sh** - Create and switch to Git worktrees
- **employee-code.sh** - Retrieve employee code for branch naming

### Skills

Language and framework-specific best practices in the [skills/](skills/) directory:

- **css-or-sass/** - CSS/Sass development guidelines
- **javascript/** - JavaScript coding standards
- **react/** - React development patterns
- **testing/** - Testing strategies and conventions
- **typescript/** - TypeScript best practices
- **workflow/** - General development workflow

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
