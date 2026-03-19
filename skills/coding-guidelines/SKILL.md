---
name: coding-guidelines
description: >
  Use when performing any coding task, writing new code, refactoring, or reviewing code/PRs.
  Triggers on: code writing, code review, refactoring, PR review, implementing features, fixing bugs.
metadata:
  version: 1.0
  last_updated: 08/03/2026 19:02
---

# Coding Guidelines

Comprehensive coding standards for JavaScript, TypeScript, React, CSS/SASS, and testing. Consult the relevant reference files in `references/` for language-specific rules.

## Cross-Cutting Principles

- **KISS** - simplest solution that works; avoid over-engineering
- **DRY** - extract shared logic only after 3+ repetitions
- **YAGNI** - don't build for hypothetical future requirements
- **SOLID** - single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion
- **Fail fast** - validate at boundaries, surface errors early
- **Immutability** - prefer immutable data structures; avoid mutation

## General Rules

- Prefer readability over cleverness
- Small, focused functions (~20 lines max)
- Small, focused files (~300 lines max)
- Meaningful names: variables describe content, functions describe action, booleans are questions (`isActive`, `hasPermission`)
- No magic numbers/strings — use named constants
- Guard clauses over nested conditionals (early returns)
- No commented-out code — use version control
- Imports: external deps first, then internal, then relative (with blank line separators)

## Code Review Checklist

When reviewing code, verify:

1. **Correctness** - does it do what it claims?
2. **Edge cases** - null, empty, boundary values handled?
3. **Security** - no injection, XSS, or data leaks?
4. **Performance** - no unnecessary re-renders, N+1 queries, or unbounded loops?
5. **Types** - proper typing, no `any` escape hatches?
6. **Tests** - adequate coverage for new/changed logic?
7. **Naming** - clear, consistent, self-documenting?
8. **Simplicity** - is there a simpler way?

## Reference Files

Guidelines chain where applicable — each file extends its parent:

- `references/javascript.md` - JS conventions & patterns (base)
- `references/typescript.md` - TS type system & strict mode (extends javascript.md)
- `references/react.md` - React component patterns & hooks (extends typescript.md)
- `references/mantine.md` - Mantine component library patterns (extends react.md)
- `references/graphql.md` - GraphQL + Apollo codegen patterns (extends typescript.md)
- `references/css-or-sass.md` - Styling conventions
- `references/tailwind.md` - Tailwind CSS utility-first workflow (extends css-or-sass.md)
- `references/test.md` - Testing strategy & patterns

## Assets

Supplementary resources in `assets/` for styling decisions and code review examples.

### `assets/styling-decision-tree.md`

Reference when a user asks which styling approach to use or when starting a new component in a project with multiple styling tools. Provides a flowchart mapping project context (Mantine, Tailwind, SASS, plain CSS) to the correct approach.

### `assets/before-after-snippets.md`

Load relevant snippets during code review to show concrete before/after examples when pointing out anti-patterns. Covers: Tailwind, React, TypeScript, CSS, Testing, JavaScript, GraphQL.

## Scripts

Utility scripts in `scripts/` support the skill's workflows. Resolve script paths relative to this SKILL.md file. Run via `bash` and pass the user's project directory as an argument.

### `scripts/select-guidelines.sh [--diff | PROJECT_DIR]`

Run at the **start of any coding task or code review** to auto-detect which reference files are relevant. Accepts either a project directory path (scans `package.json` and project files), or `--diff` to read a unified diff from stdin (e.g., `gh pr diff 123 | select-guidelines.sh --diff`). Outputs one reference filename per line.

### `scripts/tailwind-lint.sh [DIRECTORY]`

Run during **code review when Tailwind is in use** to find inline Tailwind utility classes in JSX/TSX files that haven't been extracted to CSS Modules. Reports file:line matches with a summary count.

### `scripts/pr-checklist.sh [--staged] [BASE_BRANCH]`

Run during **PR review** to generate a focused markdown review checklist based on changed files. Auto-detects base branch (staging > development > main) if not specified. Categorizes changes and includes relevant guideline items.
