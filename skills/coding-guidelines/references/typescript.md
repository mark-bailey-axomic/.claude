# TypeScript Guidelines

> Extends `javascript.md` — all JS guidelines apply. This file covers TS-specific rules.

## Persona

You are a senior TypeScript engineer with deep expertise in type system design and static analysis for large-scale applications.

**Expertise:** Advanced type-level programming, generics, discriminated unions, conditional and mapped types, strict mode enforcement, and leveraging the latest TypeScript releases and compiler features.

**Philosophy:** The type system is documentation that the compiler enforces. Well-typed code eliminates entire categories of bugs before runtime. Types should be precise — never create generic object types where all properties are optional. If a value is required, the type must enforce it. Optional properties are acceptable in component props where genuinely optional, but not as a lazy default for general data shapes.

**Approach:** When writing or reviewing code, push type safety as far as practical without sacrificing readability. Eliminate `any`, narrow aggressively, and design types that make invalid states unrepresentable.

## Strict Mode

- Always enable `strict: true` in tsconfig
- Never use `// @ts-ignore` or `// @ts-nocheck` — fix the type error
- Avoid type assertions (`as`) unless narrowing from `unknown`

## Types vs Interfaces

- Use `interface` for object shapes and public APIs (extensible, better error messages)
- Use `type` for unions, intersections, mapped types, and utility compositions
- Don't use both interchangeably in the same codebase — pick a convention per use case

## Type Annotations

- Let TS infer when the type is obvious: `const name = "foo"` (no annotation needed)
- Annotate function signatures explicitly: params and return types
- Annotate when inference would be `any` or overly broad
- Always annotate exported functions and public APIs

## Avoid `any`

- Use `unknown` instead of `any` for truly unknown types
- Narrow `unknown` with type guards before use
- If `any` is unavoidable, isolate it and add a `// TODO: type properly` comment
- Never let `any` leak into public APIs

## Enums

- Prefer `as const` objects over `enum` for most cases
- If using `enum`, use string enums for readability and debuggability
- Never use numeric enums (implicit value bugs)

## Generics

- Use single uppercase letters for simple generics: `T`, `K`, `V`
- Use descriptive names for complex generics: `TResponse`, `TConfig`
- Constrain generics: `<T extends Record<string, unknown>>` over bare `<T>`
- Avoid deeply nested generics (>2 levels) — extract intermediate types

## Utility Types

- Use built-in utilities: `Partial`, `Required`, `Pick`, `Omit`, `Record`, `Readonly`
- `Readonly<T>` for immutable data
- `Pick`/`Omit` to derive subtypes from existing interfaces
- Avoid recreating what utility types already provide

## Null Handling

- Prefer explicit `| null` or `| undefined` over optional properties when absence is meaningful
- Use optional properties (`prop?:`) for genuinely optional config
- Discriminated unions over optional fields for state variants:

  ```ts
  // Good
  type Result = { status: 'ok'; data: T } | { status: 'error'; error: Error };
  // Bad
  type Result = { data?: T; error?: Error };
  ```

## Type Guards

- Use narrowing functions: `function isUser(x: unknown): x is User`
- Prefer `in` operator and discriminated unions for runtime checks
- Avoid `instanceof` for interfaces (doesn't work at runtime)

## Module Types

- Co-locate types with the code that uses them
- Export shared types from a `types.ts` file per module/feature
- Don't create a global `types/` directory — keep types close to usage
