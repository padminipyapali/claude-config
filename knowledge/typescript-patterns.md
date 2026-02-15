# TypeScript / Node.js Patterns

Cross-project learnings for TypeScript and Node.js development.

## Async Patterns

- **Don't mark functions `async` unless they `await`.** An `async` function without `await` silently wraps the return in a `Promise`, changing `() => void` to `() => Promise<void>` without adding value.
- **Fire-and-forget operations MUST have `.catch()` handlers.** Prevents unhandled promise rejections. Even non-critical SSE writes need `.catch(() => {})`.
- **Fire-and-forget try/catch granularity.** When a method is called with `.catch()` at a call site, EVERY `await` inside that method must have its own try/catch. A single outer try/catch doesn't satisfy the contract — one failure skips all subsequent awaits.
- **Async initialization ordering.** Map the dependency graph of `start()` calls. If service B can trigger work depending on service A, await A before starting B. Anti-pattern: `telegram.start(); reminderScheduler.start();` (not awaited).
- **Async state: merge, don't replace.** When loading data asynchronously, never use `prev.length === 0 ? loaded : prev` — this drops loaded data if the user acts fast. Dedup-merge instead: `[...loaded, ...prev.filter(m => !seen.has(m.id))]`.

## Type Safety

- **Use existing union types, not `string`.** When a parameter represents a constrained set (channel types, statuses), use the union type. `string` creates a type hole.
- **Runtime arrays derived from TS types need "keep in sync" comments.** Types are erased at runtime.
- **Exhaustive `never` checks should throw, not return.** Fail fast on unhandled types.
- **Prefer `as UnionType` over `as any`.** When the type is known (e.g., DB string field with a CHECK constraint matching a TS union), cast precisely.
- **Shared type changes require test mock updates.** After adding a field to a shared interface, grep for all `createMock*` factories.
- **Use `as const` on lookup objects when using `keyof typeof`.** `Record<string, V>` erases literal key types, so `keyof typeof OBJ` resolves to `string` — defeating the purpose of type narrowing. Declare with `as const` to preserve a concrete union of keys. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **Import types directly under automatic JSX transform.** With `jsx: "react-jsx"`, `React` is not in scope. Use `import type { ComponentType } from 'react'` not `React.ComponentType`, or the type reference will fail at compile time. <!-- Source: PR review, command-center #3, 2026-02-14 -->

## API Boundaries

- **Input type validation.** `(content ?? "").trim()` silently coerces `null` but crashes on `42` or `{obj: true}`. Use `typeof content !== "string"` guard before `.trim()`.
- **Validate query param enum values.** Reject invalid values with 400, don't silently fall back to `undefined`.
- **Guard API response shape before destructuring.** Even with TypeScript generics on `api.get<T>()`, check `Array.isArray()` before `.filter()/.map()`.
- **Validate date strings before formatting.** `new Date(str)` can produce `NaN` timestamps. Always check `isNaN(d.getTime())` and return a fallback (`""`, `"—"`) instead of displaying `"NaN ago"` or `"Invalid Date"`. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **Always `?? []` when mapping API response arrays.** Servers can return unexpected shapes even when TypeScript says the field is required.

## Environment Variables

- **Numeric env vars need NaN check + range validation + fallback logging.** `parseInt` can return NaN; bounded values (hours 0-23, ports 1-65535) need range checks.
- **Fail-fast timezone validation.** Validate timezone strings immediately with `Intl.DateTimeFormat("en-US", { timeZone: tz })` in a try/catch. Invalid timezones throw `RangeError`.

## Error Handling

- **Error swallowing in catch blocks.** A catch returning `[]` or a default masks real DB outages. Only return defaults for EXPECTED edge cases (not found, no embedding). Unexpected errors (connection failure, query syntax) must propagate.
- **Broad vs. narrow try/catch scope.** Don't wrap entire methods in one try/catch. If multiple awaits fail for different reasons, split the try blocks.
- **Register global error handlers on long-running services.** Per-request error handling is necessary but not sufficient.
- **Log errors with context (request ID, user ID, operation) but never secrets or PII.** Log `error.name`, not `error.message` (may contain user content).

## Observer / Pub-Sub Patterns

- **Snapshot callback arrays before iteration.** When callbacks can unsubscribe during invocation (observer/event-emitter patterns), iterate over `[...callbacks]` not the live array. `splice()` during iteration skips entries. <!-- Source: PR review, command-center #3, 2026-02-14 -->

## Input Validation

- **Whitespace-only strings are truthy in JavaScript.** `!text` does NOT catch `"   "` — whitespace-only strings are truthy and bypass empty guards. Always `.trim()` at the earliest pipeline point so downstream logic operates on normalized input. Guard on `!text.trim()` not `!text`. <!-- Source: BUG-T014, second-brain -->
- **Narrow try/catch to I/O only; guard `Invalid Date` from external APIs.** A broad try/catch around fetch + JSON transform means a formatting bug silently drops all fetched data. Wrap only the network call in try/catch. Then guard each data transformation separately — especially `new Date()` on external strings, which can produce `Invalid Date` that propagates silently through formatters. <!-- Source: BUG-T016, second-brain -->

## Code Hygiene

- **Early return before dead computation.** If a branch exits early, place it before computing values it won't use.
- **Remove dead code from iterative development.** During feature work, early iterations leave unused variables, imports, and helpers.
- **Remove unnecessary `as const`.** String literals assigned to typed fields don't need `as const` — TS infers from context.
- **Resource lifecycle symmetry.** If a service creates a resource (Pool, timer, connection), expose `shutdown()`/`close()`.

## Build & Dependencies

- **Build tools in devDependencies.** @types/*, typescript, vite, tsx, vitest.
- **npm workspaces use `*` not `workspace:*`.** The `workspace:` protocol is pnpm/yarn.
- **Import constants from shared packages.** Never duplicate shared constants across consuming packages.

---
*Sources: second-brain, lexica, command-center, nanny-management*
