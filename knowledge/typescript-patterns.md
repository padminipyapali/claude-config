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

- **Type runtime validation sets as `Set<UnionType>` not `Set<string>`.** When a `Set` is used to validate input against a TypeScript union (e.g., `SessionNoteSource = "telegram" | "web" | "cli"`), declare it as `Set<SessionNoteSource>` not `Set<string>`. The compiler catches drift if a value is added/removed from the union but not the Set. Pair with `satisfies` for arrays: `["a", "b"] as const satisfies readonly MyUnion[]`. <!-- Source: PR review, command-center #30, 2026-02-20 -->

## API Boundaries

- **Input type validation.** `(content ?? "").trim()` silently coerces `null` but crashes on `42` or `{obj: true}`. Use `typeof content !== "string"` guard before `.trim()`.
- **Validate query param AND request body enum values against a Set.** Reject invalid values with 400, don't silently fall back to `undefined`. This applies to both query params and JSON body fields (e.g., `feedback`, `discardReason`). Declare a `VALID_*` Set at module scope and validate with `.has()`. When validation passes, cast to the union type. When it fails, list valid values in the error message using `[...set].join(", ")`. <!-- Strengthened: PR review, second-brain #211, 2026-02-23 -->
- **Check `success` flag on API responses before proceeding.** When an API returns `{ success: boolean }`, always check `result.success` before updating UI state or triggering side effects. A resolved promise with `success: false` is not an error — `catch` won't fire. Without the check, the UI shows a false-positive success state (e.g., "Feedback submitted" when the server rejected it). Pattern: `const result = await api.submit(...); if (!result.success) throw new Error("...");`. <!-- Source: PR review, second-brain #215, 2026-02-24 -->
- **Guard API response shape before destructuring.** Even with TypeScript generics on `api.get<T>()`, check `Array.isArray()` before `.filter()/.map()`.
- **Validate date strings before formatting — `new Date("invalid")` is truthy.** `new Date(str)` with invalid input produces a Date object that is truthy (`if (date)` passes!) but has `getTime() === NaN`. A truthiness guard does NOT catch invalid dates. Always check `Number.isNaN(date.getTime())` or `Number.isFinite(date.getTime())` and return a fallback (`""`, `null`, `"—"`) instead of displaying `"NaN ago"` or `"Invalid Date"`. This is especially dangerous when constructing Dates from database columns (pg returns various types for timestamp columns) or LLM-extracted strings — a bad value silently becomes Invalid Date, which serializes as the string `"Invalid Date"` in JSON responses. <!-- Strengthened: PR review, second-brain #246, 2026-02-25; original: command-center #3, 2026-02-14 -->
- **Use `Number.isFinite()` to detect Invalid Date, not just `isNaN`.** `new Date("bad").getTime()` returns `NaN`, which silently fails ALL comparisons (`NaN > x` is false, `NaN < x` is false, `NaN === NaN` is false). This means conditionals like `if (date > new Date())` silently take the wrong branch. Use `Number.isFinite(date.getTime())` as the validation check — it catches `NaN`, `Infinity`, and non-number values in one guard. <!-- Source: PR review, second-brain #187, 2026-02-20 -->
- **Always `?? []` when mapping API response arrays.** Servers can return unexpected shapes even when TypeScript says the field is required. This applies especially to GraphQL: the generated types may declare a field as non-optional, but the actual API can return `null` for nested fields (e.g., `repo.mergedPrs.nodes`). Always use optional chaining + nullish coalescing: `response?.nodes ?? []`. When fixing this in a service, grep the entire codebase for sibling services using the same GraphQL query shape — the same unguarded access is very likely to exist there too. <!-- Source: PR review, command-center #23, 2026-02-19 -->
- **Reject non-string query params explicitly.** Express parses repeated query params (`?x=A&x=B`) as arrays. A `typeof x === "string"` check silently skips arrays, disabling the feature. Guard with `typeof x !== "string"` → 400 before parsing. <!-- Source: PR review, second-brain #100, 2026-02-15 -->

## ESM / Module Patterns

- **Use `fileURLToPath(import.meta.url)` for path resolution in ESM, not `new URL(import.meta.url).pathname`.** The `.pathname` property preserves percent-encoding (e.g., `%20` for spaces) and on Windows returns a leading `/C:/...` which is invalid. `fileURLToPath()` from `node:url` correctly decodes and normalizes the path on all platforms. When fixing this in one file, grep the repo for `new URL(import.meta.url).pathname` to catch all sibling instances. <!-- Source: PR review, command-center #33, 2026-02-20 -->

## Environment Variables

- **Numeric env vars need NaN check + range validation + fallback logging.** `parseInt` can return NaN; bounded values (hours 0-23, ports 1-65535) need range checks.
- **Fail-fast timezone validation.** Validate timezone strings immediately with `Intl.DateTimeFormat("en-US", { timeZone: tz })` in a try/catch. Invalid timezones throw `RangeError`.

## Error Handling

- **`process.exit()` inside try bypasses finally.** `process.exit(1)` skips the `finally` block entirely — cleanup code (pool.end(), file handles, temp files) never runs. Use `process.exitCode = 1; return;` inside try blocks to allow finally to execute. <!-- Source: PR review, second-brain #204, 2026-02-22 -->
- **Error swallowing in catch blocks.** A catch returning `[]` or a default masks real DB outages. Only return defaults for EXPECTED edge cases (not found, no embedding). Unexpected errors (connection failure, query syntax) must propagate.
- **When adding throws to a previously-silent function, wrap ALL callers in try/catch.** If a function previously returned `null` or a default on bad input and you add `throw new Error()` validation, every caller becomes a crash site. Grep for all call sites and add error handling. This is especially critical when the function's inputs come from LLM extraction — bad output is the expected case, not the edge case. Pattern: search for the function name across the codebase, verify each caller either has a try/catch or is itself called within one. <!-- Source: PR review, second-brain #187, 2026-02-20 -->

## Observer / Pub-Sub Patterns

- **Snapshot callback arrays before iteration.** When callbacks can unsubscribe during invocation (observer/event-emitter patterns), iterate over `[...callbacks]` not the live array. `splice()` during iteration skips entries. <!-- Source: PR review, command-center #3, 2026-02-14 -->
- **Snapshot mutable collections before notify loops that may re-enter.** When iterating a collection (e.g., pending queue) and calling callbacks that could mutate it (e.g., `onComplete` triggers `enqueue`), snapshot the collection and clear the original BEFORE the loop. Otherwise new items added during iteration are lost when the collection is cleared after the loop. Pattern: `const toProcess = this.items; this.items = []; for (const item of toProcess) { ... }`. <!-- Source: PR review, command-center #30, 2026-02-20 -->

## Input Validation

- **Whitespace-only strings are truthy in JavaScript.** `!text` does NOT catch `"   "` — whitespace-only strings are truthy and bypass empty guards. Always `.trim()` at the earliest pipeline point so downstream logic operates on normalized input. Guard on `!text.trim()` not `!text`. <!-- Source: BUG-T014, second-brain -->
- **At service boundaries, use `.trim() || null` not `?? null` for optional string normalization.** The nullish coalescing operator `?? null` preserves empty strings `""` and whitespace-only strings `"   "`, which bypass downstream validation guards (e.g., `if (dueDate)` passes for `""`). Use `input?.trim()` then `|| null` to collapse whitespace-only and empty strings to `null`. This is especially important for user-provided optional fields (dates, descriptions, tags) that flow into DB queries or conditional logic. <!-- Source: PR review, second-brain #197, 2026-02-20 -->
- **Normalize internal punctuation when matching against token sets.** When checking user input against a set of keywords/tokens (e.g., `["yes", "no", "skip"]`), stripping only trailing punctuation is insufficient — `"yes, please"` won't match `"yes"`. Normalize by removing ALL non-alphanumeric characters or splitting on word boundaries before matching. Pattern: `input.replace(/[^\w\s]/g, "").split(/\s+/).some(word => tokenSet.has(word.toLowerCase()))`. <!-- Source: PR review, second-brain #187, 2026-02-20 -->
- **Narrow try/catch to I/O only; guard `Invalid Date` from external APIs.** A broad try/catch around fetch + JSON transform means a formatting bug silently drops all fetched data. Wrap only the network call in try/catch. Then guard each data transformation separately — especially `new Date()` on external strings, which can produce `Invalid Date` that propagates silently through formatters. <!-- Source: BUG-T016, second-brain -->

## Date / Timezone Pitfalls

- **`new Date("YYYY-MM-DDT00:00:00")` without `Z` suffix parses as server local time.** This silently shifts dates when the server timezone differs from the user's. Always append `Z` for UTC, or use `localToUtc()` / `Date.UTC()` when the date represents a specific timezone. Affects both production code and test helpers — flaky CI tests are the first symptom. <!-- Source: PR review, second-brain #131, 2026-02-16 -->
- **When truncating strings to a max length with a suffix, subtract the suffix length from the limit.** `str.slice(0, 4090) + "\n[truncated]"` produces 4102 chars, exceeding a 4096 limit. Use `str.slice(0, limit - suffix.length) + suffix`. <!-- Source: PR review, second-brain #131, 2026-02-16 -->
- **`new Date(year, month, day)` silently normalizes invalid dates.** `new Date(2026, 1, 30)` (Feb 30) doesn't throw — it normalizes to March 2. When parsing user-provided date strings via split-and-construct, verify the result matches the input: `candidate.getFullYear() === year && candidate.getMonth() === month - 1 && candidate.getDate() === day`. If not, treat as invalid. This applies to any date picker fallback path or config file parsing. <!-- Source: PR review, nanny-app #28, 2026-02-19 -->
- **Normalize date ranges to UTC midnight for daily bucketing.** When computing a `sinceDate` for daily breakdowns, use `new Date(Date.UTC(y, m, d))` — not `new Date(Date.now() - N * 86400000)`. Raw subtraction preserves time-of-day, so the "today" bucket starts mid-day and excludes morning activity. Pattern: `const todayUtc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())); const sinceDate = new Date(todayUtc.getTime() - (days - 1) * 86400000);`. <!-- Source: PR review, command-center #21, 2026-02-19 -->

## Interface Implementation

- **Match interface signatures explicitly, even when TypeScript allows fewer params.** TypeScript's structural typing permits implementations to declare fewer parameters than the interface. But when sibling implementations use different subsets of the interface params, it creates confusing inconsistency. Convention: always declare all interface parameters, even if unused (prefix with `_` to satisfy linters). This makes handler registries and strategy patterns easier to read and maintain. <!-- Source: PR review, second-brain #187, 2026-02-20 -->

## Import Hygiene

- **Use module-level imports, not inline `import()` types.** Inline type references like `import("../../services/entry.js").TodoMatch` are harder to read and break import organization conventions. Hoist them to module-level `import type { TodoMatch } from "../../services/entry.js"` for consistency and discoverability. <!-- Source: PR review, second-brain #187, 2026-02-20 -->

## Code Hygiene

- **Remove unnecessary `as const`.** String literals assigned to typed fields don't need `as const` — TS infers from context.
- **Normalize newlines in single-line output functions.** When a function produces a single-line string (e.g., a numbered list item, a summary row, a log line), replace `\n` with a space or strip it entirely. User-provided or LLM-generated text can contain unexpected newlines that break the surrounding format (e.g., a numbered list becomes misaligned: `1. Buy\nmilk\n2. Call dentist`). Guard: `text.replace(/\n/g, " ").trim()` in any function that returns a single-line string. <!-- Source: PR review, second-brain #187, 2026-02-20 -->
- **`toLocaleString` + `new Date()` for timezone offset is fragile.** The pattern of computing timezone offsets via `new Date(date.toLocaleString("en-US", { timeZone }))` relies on both the `toLocaleString` output and the `new Date()` reparsing step being in the server's local timezone, which happens to cancel out. This is susceptible to locale-dependent parsing quirks and DST transitions. Use `Intl.DateTimeFormat("en-US", { timeZone }).formatToParts(date)` instead — it returns structured data (year, month, day, hour, minute) without needing string reparsing. <!-- Source: PR review, second-brain #164, 2026-02-19 -->

---
*Sources: second-brain, lexica, command-center, nanny-management*
