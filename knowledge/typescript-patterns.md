# TypeScript / Node.js Patterns

Cross-project learnings for TypeScript and Node.js development.

## Async Patterns

- **Fire-and-forget try/catch granularity.** When a method is called with `.catch()` at a call site, EVERY `await` inside that method must have its own try/catch. A single outer try/catch doesn't satisfy the contract — one failure skips all subsequent awaits.
- **Async initialization ordering.** Map the dependency graph of `start()` calls. If service B can trigger work depending on service A, await A before starting B. Anti-pattern: `telegram.start(); reminderScheduler.start();` (not awaited).
- **Async state: merge, don't replace.** When loading data asynchronously, never use `prev.length === 0 ? loaded : prev` — this drops loaded data if the user acts fast. Dedup-merge instead: `[...loaded, ...prev.filter(m => !seen.has(m.id))]`.
- **Batch concurrent external API calls with a cap.** When fetching details for N items from an external API, use `Promise.allSettled` with `.slice(0, MAX)` rather than a sequential loop. Sequential loops are slow; unbounded `Promise.all` risks rate limits. Pattern: filter new items, `.slice(0, 10)`, `Promise.allSettled(items.map(...))`, then collect fulfilled results and log rejected ones. <!-- Source: PR review, command-center #12, 2026-02-15 -->

## Type Safety

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
- **Reject non-string query params explicitly.** Express parses repeated query params (`?x=A&x=B`) as arrays. A `typeof x === "string"` check silently skips arrays, disabling the feature. Guard with `typeof x !== "string"` → 400 before parsing. <!-- Source: PR review, second-brain #100, 2026-02-15 -->

## Environment Variables

- **Numeric env vars need NaN check + range validation + fallback logging.** `parseInt` can return NaN; bounded values (hours 0-23, ports 1-65535) need range checks.
- **Fail-fast timezone validation.** Validate timezone strings immediately with `Intl.DateTimeFormat("en-US", { timeZone: tz })` in a try/catch. Invalid timezones throw `RangeError`.

## Error Handling

- **Error swallowing in catch blocks.** A catch returning `[]` or a default masks real DB outages. Only return defaults for EXPECTED edge cases (not found, no embedding). Unexpected errors (connection failure, query syntax) must propagate.

## Observer / Pub-Sub Patterns

- **Snapshot callback arrays before iteration.** When callbacks can unsubscribe during invocation (observer/event-emitter patterns), iterate over `[...callbacks]` not the live array. `splice()` during iteration skips entries. <!-- Source: PR review, command-center #3, 2026-02-14 -->

## Input Validation

- **Whitespace-only strings are truthy in JavaScript.** `!text` does NOT catch `"   "` — whitespace-only strings are truthy and bypass empty guards. Always `.trim()` at the earliest pipeline point so downstream logic operates on normalized input. Guard on `!text.trim()` not `!text`. <!-- Source: BUG-T014, second-brain -->
- **Narrow try/catch to I/O only; guard `Invalid Date` from external APIs.** A broad try/catch around fetch + JSON transform means a formatting bug silently drops all fetched data. Wrap only the network call in try/catch. Then guard each data transformation separately — especially `new Date()` on external strings, which can produce `Invalid Date` that propagates silently through formatters. <!-- Source: BUG-T016, second-brain -->

## Code Hygiene

- **Remove unnecessary `as const`.** String literals assigned to typed fields don't need `as const` — TS infers from context.

---
*Sources: second-brain, lexica, command-center, nanny-management*
