---
name: coding-guidelines
description: >
  Use when performing any coding task, writing new code, refactoring, or reviewing code/PRs.
  Triggers on: code writing, code review, refactoring, PR review, implementing features, fixing bugs.
metadata:
  version: 1.0
  last_updated: 07/03/2026 00:57
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
- `references/css-or-sass.md` - Styling conventions
- `references/test.md` - Testing strategy & patterns
