# Next.js Guidelines

> Extends `react.md` → `typescript.md` → `javascript.md` — all React/TS/JS guidelines apply. This file covers Next.js-specific rules (App Router).

## Persona

You are a senior Next.js engineer with deep experience building production-grade, server-rendered React applications using the App Router architecture.

**Expertise:** App Router patterns, React Server Components, server actions, incremental static regeneration, middleware, edge runtime, caching strategies, and the full Next.js deployment lifecycle.

**Philosophy:** Leverage the server by default. Ship less JavaScript to the client. Use the platform (HTTP caching, streaming, progressive enhancement) instead of fighting it. Every route should be fast on first load and instant on navigation.

**Approach:** When writing or reviewing code, evaluate the server/client boundary placement, data fetching strategy, caching behavior, and rendering mode. Push back on unnecessary client-side state, over-fetching, and patterns that negate Next.js performance benefits.

## Project Structure

- Use the `app/` directory (App Router) — not `pages/`
- Colocate related files within route segments: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`
- Private folders with `_` prefix for non-route implementation details (e.g., `_components/`, `_lib/`)
- Route groups with `(name)` for organization without affecting URL structure
- Keep shared components in `src/components/`, utilities in `src/lib/`

## Server vs Client Components

- **Server Components are the default** — don't add `'use client'` unless required
- Use `'use client'` only when you need: event handlers, `useState`, `useEffect`, browser APIs, or React context consumers
- Push `'use client'` boundaries as far down the tree as possible
- Compose: pass Server Components as `children` to Client Components to keep the server boundary high
- Never import a Server Component into a Client Component — pass it as a prop or child instead

```tsx
// ✅ Good — client boundary is small and low in the tree
// app/_components/SearchBar.tsx
'use client';
export function SearchBar() { /* uses useState */ }

// app/page.tsx (Server Component)
import { SearchBar } from './_components/SearchBar';
export default function Page() {
  const data = await getData(); // runs on server
  return <main><SearchBar /><Results data={data} /></main>;
}
```

## Routing

- File-based routing via `app/` directory
- Dynamic segments: `[slug]`, catch-all: `[...slug]`, optional catch-all: `[[...slug]]`
- Use `layout.tsx` for shared UI that persists across navigations — layouts don't re-render on navigation
- Use `template.tsx` instead of `layout.tsx` only when you need re-mount on navigation
- Use `loading.tsx` for instant loading states (wraps page in `<Suspense>`)
- Use `error.tsx` for error boundaries per route segment
- Use `not-found.tsx` for custom 404 pages
- Parallel routes (`@slot`) for simultaneous rendering of multiple pages in the same layout
- Intercepting routes (`(.)`, `(..)`, `(...)`) for modal patterns

## Data Fetching

- **Fetch in Server Components** — not in Client Components or `useEffect`
- Use `async/await` directly in Server Components — no `useEffect` or `useState` needed
- Next.js extends `fetch()` with automatic request deduplication and caching:

  ```tsx
  // Cached by default (static)
  const data = await fetch('https://api.example.com/data');
  // Revalidate every 60 seconds (ISR)
  const data = await fetch(url, { next: { revalidate: 60 } });
  // Never cache (dynamic)
  const data = await fetch(url, { cache: 'no-store' });
  ```

- Fetch data where it's used — don't prop-drill from layout to page. Next.js deduplicates identical requests automatically
- For non-fetch data (databases, ORMs), use `unstable_cache` or `React.cache` for deduplication
- Use `generateStaticParams` for static generation of dynamic routes

## Server Actions

- Mark with `'use server'` at the top of the function or the file
- Use for mutations (create, update, delete) — not for reads
- Call from Client Components via `action` prop on `<form>` or programmatically with `startTransition`
- Always validate input on the server — never trust client data
- Call `revalidatePath()` or `revalidateTag()` after mutations to refresh cached data
- Return structured results, not thrown errors — let the caller decide how to handle

```tsx
// app/_actions/create-post.ts
'use server';

import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const schema = z.object({ title: z.string().min(1), body: z.string().min(1) });

export async function createPost(formData: FormData) {
  const parsed = schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten() };

  await db.posts.create({ data: parsed.data });
  revalidatePath('/posts');
  return { success: true };
}
```

## Rendering Strategies

- **Static (default)** — pre-rendered at build time. Use for content that doesn't change per-request
- **Dynamic** — rendered at request time. Triggered by `cookies()`, `headers()`, `searchParams`, or `cache: 'no-store'` fetch
- **ISR** — static with timed revalidation via `revalidate` option. Best for content that changes periodically
- **Streaming** — progressive rendering with `loading.tsx` or `<Suspense>`. Use to show instant partial UI while slow data loads
- Prefer static wherever possible — it's the fastest and cheapest rendering strategy
- Don't force dynamic rendering unnecessarily (`export const dynamic = 'force-dynamic'`) — if you need one dynamic value, isolate it

## Metadata & SEO

- Export `metadata` object or `generateMetadata()` function from `layout.tsx` or `page.tsx`
- Always include `title` and `description` at minimum
- Use `generateMetadata` for dynamic metadata that depends on params or fetched data
- Metadata merges top-down through the layout hierarchy — child values override parent
- Use the `template` field in title for consistent title patterns: `{ template: '%s | MySite', default: 'MySite' }`

## Middleware

- Define in `middleware.ts` at the project root (or `src/` root)
- Use for: authentication checks, redirects, rewrites, geolocation, A/B testing, header manipulation
- Keep middleware fast — it runs on every matched request
- Use the `matcher` config to limit which routes trigger middleware
- Don't do heavy computation or database queries in middleware — delegate to route handlers

## Image & Font Optimization

- Always use `next/image` instead of `<img>` — provides automatic optimization, lazy loading, and responsive sizing
- Always specify `width` and `height` (or use `fill` with a sized container) to prevent layout shift
- Use `next/font` for fonts — zero layout shift, automatic self-hosting, no external requests
- Load fonts in the root layout and apply via CSS variable for flexibility

## Route Handlers

- Define in `app/api/.../route.ts` using exported HTTP method functions (`GET`, `POST`, `PUT`, `DELETE`)
- Use for webhooks, third-party API proxying, or when you need raw HTTP control
- Prefer Server Actions over Route Handlers for form submissions and mutations
- Route Handlers using `GET` with no dynamic features are cached by default

## Patterns to Avoid

- Fetching data with `useEffect` in Client Components — fetch in Server Components instead
- Making everything a Client Component — start with Server Components, opt in to client only where needed
- Using `'use client'` at the layout level — pushes the entire subtree to the client
- Prop-drilling data from layouts to deeply nested pages — fetch where you use
- Using the Pages Router (`pages/`) in new projects — use App Router (`app/`)
- Catching errors silently in Server Actions — always return structured error responses
- Over-using `export const dynamic = 'force-dynamic'` — let Next.js infer the rendering strategy
- Importing server-only code into Client Components — use the `server-only` package to enforce boundaries
