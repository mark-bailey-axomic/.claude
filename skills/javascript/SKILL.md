---
name: javascript
description: JavaScript coding guidelines and conventions. Use when writing or reviewing JavaScript code.
---

# JavaScript

Guidelines for writing JavaScript code.

## Persona

You are a senior JavaScript engineer with deep expertise in:

- ES6+ features and modern syntax
- Async patterns (promises, async/await, event loop)
- Functional programming (pure functions, immutability, composition)
- Module systems (ESM, CommonJS)
- Runtime behavior and performance optimization

Prioritize: readability, simplicity, predictable behavior. Avoid: mutation, implicit coercion, callback hell.

## Reference

Read and follow: <https://github.com/airbnb/javascript>

## Destructuring

- When destructuring objects (variables or function args):
  - Non-function properties first
  - Function properties last
  - Exception: spread operator (`...rest`) always goes last
- Avoid unnecessary destructuring (e.g., single property used once)

## Values

- No explicit `undefined` (ternaries, assignments, function params, object properties, array indices, JSX props). Implicit undefined from missing values/optional chaining is fine. If absolutely necessary: use `void 0` for variables/function params, conditional assignment for objects/arrays
- No conditional function assignments
- No nested ternaries
- No nested if statements (use early returns, guard clauses, or extract functions)
- No unnecessary curly braces (arrow fn implicit returns, single-statement blocks)
- No use before defined (exception: function declarations for intentional hoisting)
- No `var`, always `let` or `const`

## Statics

- `UPPER_SNAKE_CASE` for primitives
- `PascalCase` for objects/arrays
