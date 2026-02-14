# Codebase Patterns

## Project structure
- Monorepo: `packages/server`, `packages/web`, `packages/shared`
- Build: `npm run build` (all workspaces), test: `npm test`
- Server entrypoint: `packages/server/src/server.ts`
- Pipeline orchestrator: `packages/server/src/processor/message-processor.ts`
- Services: classifier, embedding, entry, response, search (all in `packages/server/src/services/`)
- Channel adapters: `packages/server/src/channels/telegram.ts`

## Service interfaces
- All services have an interface + implementation class pattern (e.g. `EntryService` / `PostgresEntryService`)
- `MessageProcessorDeps` aggregates all service interfaces for dependency injection
- Tests mock each service via `vi.fn()`

## Fire-and-forget pattern
Used for: embedding, AI response storage, TODO splitting, channel response ID storage.
```typescript
this.deps.embedding
  .embed(text)
  .then((emb) => this.deps.entry.updateEmbedding(entryId, emb))
  .catch((err) => console.error("...", entryId, err));
```
Tests use `vi.waitFor()` to assert on async side effects.

## Identity resolution
- `message.userId` = channel-specific ID (Telegram chat ID string)
- `userId` (after `findOrCreateUser`) = internal DB UUID
- Outbound calls to channels need the channel ID, not the DB UUID

## Docs to update on PRs
- `docs/BUGS.md` — bug fixes
- `docs/DECISIONS.md` — design decisions
- `docs/PRODUCT_SPEC.md` — new features
- `docs/TODO_HANDLING.md` — TODO-specific design
- `docs/QA.md` — technical Q&A

## Common PR Review Anti-Patterns (from PR #23 and earlier)

Before committing, verify the following:

### 1. Dead code from iterative development
During feature development, early iterations leave behind unused variables, imports, and helper functions. The final implementation may use a completely different approach.
**Check:** Search for unused variables/imports in every file you touched. Look for variables that were created for an earlier approach but never referenced in the final code (e.g., an `Intl.DateTimeFormat` formatter created but replaced by `formatToParts()`).

### 2. Server-timezone-dependent date computation
`new Date(someDate.toLocaleString("en-US", { timeZone: tz }))` is broken: the `new Date()` constructor parses the locale string using the **server's** local timezone, not the target timezone. This works when the server runs in UTC but silently breaks otherwise.
**Correct approach:** Use `Intl.DateTimeFormat("en-US", { timeZone: tz }).formatToParts(date)` and reconstruct the date from parts explicitly.
**Check:** Grep for `new Date(.*toLocaleString` — this pattern is almost always a bug.

### 3. Loose parameter typing — use existing union types
When a callback or function parameter represents a constrained set of values (like channel types), use the existing union type (e.g., `ChannelType`) not `string`. A `string` parameter creates a type hole where invalid values flow through without TypeScript catching them.
**Check:** For every new function signature, ask: "Does any parameter represent a value from an existing enum or union type?" If yes, use that type.

### 4. Async initialization ordering
When multiple services start up, calling `serviceB.start()` without awaiting `serviceA.start()` can cause race conditions if B depends on A being ready (e.g., a reminder scheduler fires immediately but the Telegram client isn't connected yet).
**Check:** Map the dependency graph of `start()` calls. If service B can trigger work that depends on service A, ensure A is fully initialized before B starts. Chain with `.then()` or `await`.

### 5. LLM prompt example consistency
Prompt few-shot examples must be internally consistent. If an example says "tomorrow" but the date placeholder resolves to today, the LLM may learn the wrong mapping.
**Check:** Read every few-shot example and verify that the natural language description matches the expected output values. Pay special attention to date-relative terms ("tomorrow", "next Monday") vs. hardcoded date placeholders.

### 6. Input type validation at API boundaries
When parsing `req.body` fields, always validate the runtime type before calling methods on it. `(content ?? "").trim()` silently coerces `null` but crashes on `42` or `{obj: true}` with a 500. Use `typeof content !== "string"` guard before `.trim()`.
**Check:** For every `req.body` field destructured in a route handler, ask: "What happens if the client sends a number, object, or array instead of the expected type?"

### 7. Guard against missing reloaded entities
After creating a resource and then reloading it from DB (e.g., `getEntryById` after `processor.process`), always check for null. Fire-and-forget patterns, replication lag, or race conditions can cause the reload to return null. Don't return 201 with `entry: null` — return a specific 500 error.
**Check:** After any `create` → `reload` pattern, verify the reload result is guarded.

### 8. CSS modern color notation
Use `rgb(R G B / alpha%)` instead of `rgba(R, G, B, decimal)`. Stylelint enforces:
- `color-function-alias-notation`: `rgb` not `rgba`
- `color-function-notation`: modern space-separated syntax with `/` for alpha
- `alpha-value-notation`: percentage (`8%`) not decimal (`0.08`)
**Check:** Grep for `rgba(` in CSS files — should be `rgb(... / ...%)` instead.

### 9. JSDoc on test helper factories
Test helper factories (e.g., `createMessage`, `createMockProcessor`) should have JSDoc describing default values and override behavior. Per project coding guidelines: "Include JSDoc-style docstrings for functions, components, and modules where they add clarity."
**Check:** Every `create*` test helper should have a brief JSDoc.

### 10. User scoping on correlated subqueries
When adding computed fields via correlated subqueries (e.g., `(SELECT COUNT(*) FROM entries c WHERE c.parent_entry_id = e.id)`), always include `AND c.user_id = e.user_id` even if the data model guarantees children share the parent's user_id. CLAUDE.md requires explicit user scoping on ALL DB queries touching user data — defense in depth.
**Check:** Every correlated subquery or JOIN on user-owned tables must include `user_id` scoping.

### 11. Shared type changes require test mock updates
When adding a field to a shared type (e.g., `ApiEntry`), grep for all test mock factories that construct that type. Test helpers like `createMockEntry()` will fail TypeScript compilation if the new required field isn't added.
**Check:** After adding a field to a shared interface, run `grep -r 'createMock' packages/server/src` to find all factories that need updating.

### 12. Optimistic UI revert must capture previous state
When implementing optimistic updates (update UI immediately, revert on API failure), NEVER invert current state to revert (`!e.starred`). If multiple toggles race, the current state may have been flipped again and inverting gives the wrong value. Always capture the previous value BEFORE the optimistic update and restore that exact value on failure.
**Check:** Every optimistic update revert path must restore a captured snapshot, not compute the inverse.

### 13. Business logic belongs in service layer, not route handlers
Route handlers should be thin pass-throughs. If a route assembles data from multiple service calls, maps/transforms results, or contains conditional logic beyond auth/validation, that logic should be a service method. This includes: building exclude lists, calling multiple service methods, mapping between internal and API types.
**Check:** Does this route handler do anything beyond: (1) extract/validate params, (2) call one service method, (3) return the result? If yes, refactor to service.

### 14. Env var validation for bounded numeric values
When parsing env vars that represent bounded numbers (hours 0-23, ports 1-65535, etc.), always validate: (1) parseInt/parseFloat succeeded (not NaN), (2) value is within valid range, (3) log a warning with the invalid value and the fallback being used.
**Check:** Every numeric env var parse needs NaN check + range validation + fallback logging.

### 15. Fail-fast timezone validation
When accepting timezone strings as configuration (env vars or constructor params), validate immediately by calling `Intl.DateTimeFormat("en-US", { timeZone: tz })` in a try/catch. Invalid timezones throw `RangeError` — better to fail at startup than silently on the first tick.
**Check:** Constructor or startup code that accepts timezone strings must validate them.

### 16. SVG accessibility: always add `<title>` element
SVGs used as interactive icons must have a `<title>` child element for screen readers, even if the parent `<button>` has `aria-label`. Biome/linters flag `noSvgWithoutTitle`.
**Check:** Every inline `<svg>` should have a `<title>` element with descriptive text.

### 17. Use semantic `<button>` not `<div role="button">`
Never use `<div role="button" tabIndex={0} onKeyDown={...}>` — use `<button type="button">`. Native buttons provide keyboard handling (Enter, Space) for free and better accessibility semantics. Remove manual keyboard handlers when switching.
**Check:** Grep for `role="button"` — these should almost always be `<button>` elements.

### 18. Surface hook error states in UI
When a React hook returns `{ data, loading, error }`, always destructure and display the error state. Ignoring errors creates silent failures where the user sees no content and no explanation.
**Check:** Every hook that returns an error state must have that error rendered in the UI.

### 19. At-most-once dedup: set marker BEFORE the action
For idempotency guards (e.g., `lastSentDate` preventing duplicate notifications), set the marker BEFORE the action, not after. If the action fails (e.g., Telegram timeout), the marker prevents retry spam. Accept at-most-once delivery over at-least-once-with-spam.
**Check:** Every dedup marker should be set before the guarded action, not after.

### 20. Validate query param enum values at API boundary
When a query param accepts a fixed set of values (e.g., `starred=true|false`, `type=TODO|QUERY`), reject invalid values with 400 instead of silently falling back to `undefined`. This follows the "error message specificity" principle.
**Check:** Every enum query param needs an explicit invalid-value check with a 400 response.

### 6. Resource lifecycle symmetry
If a service creates a resource (e.g., `pg.Pool`, connection, timer), it should expose a `shutdown()` or `close()` method. Even if the current app doesn't call it, the absence makes testing harder and creates resource leaks in future multi-service setups.
**Note:** This is a known gap in the current codebase (no service has `shutdown()`). Flag it in PR comments but don't block on it until a refactoring pass addresses all services together.
