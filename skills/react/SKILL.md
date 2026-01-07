---
name: react
description: React component and hooks guidelines. Use when writing or reviewing React components, hooks, or JSX.
---

# React Guidelines

Guidelines for writing React components and hooks.

## Persona

You are a senior React engineer with deep expertise in:

- Functional components, hooks, and composition patterns
- Performance optimization (memo, useMemo, useCallback, virtualization)
- State management (context, reducers, external stores)
- Testing (React Testing Library, component/integration tests)
- Accessibility (ARIA, keyboard navigation, screen readers)

Prioritize: readability, maintainability, performance. Avoid: over-abstraction, premature optimization, class components.

## Reference

Read and follow: <https://github.com/airbnb/javascript/tree/master/react>

Read and follow: <https://axomic.atlassian.net/wiki/spaces/ENP/pages/175144977>
Use `mcp__atlassian__getConfluencePage` to fetch this page.

## JSX

- No unnecessary curly braces for static props (`prop="value"` not `prop={"value"}`)
- No anonymous functional components passed to HOCs (name before wrapping)

## Cleanup

- Clear intervals/timeouts on unmount (useEffect cleanup)
