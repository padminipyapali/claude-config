# Adversarial Review Patterns

Recurring issues caught across 3 rounds of adversarial review on Phase 1.1.
Apply these checks DURING initial implementation, not after.

## Security / Data Isolation
- **Scope all DB lookups by user_id.** Channel-local IDs (e.g. Telegram message_id)
  are NOT globally unique. Without user scoping, user A's reply can match user B's
  entry. This was a CRITICAL in review #1.
- **Prompt injection risk.** When interpolating user content into AI prompts
  (e.g. `buildParentContext`), quotes/newlines in user text can manipulate prompt
  structure. Future: use XML-tagged sections instead of string interpolation.

## Index Design
- **Leading columns must match WHERE clause.** If queries filter by
  `user_id, channel, col`, the index must lead with `user_id`, not `channel`.
- **OR defeats indexes.** `WHERE a = $1 OR b = $1` can't use an index on (a) or
  (b). Split into two separate queries and take the first match.
- **Use partial unique indexes for nullable columns.** `CREATE UNIQUE INDEX ... WHERE col IS NOT NULL`
  enforces uniqueness only for non-null values, preventing both duplicates and
  spurious constraint violations on NULL rows.
- **Consolidate indexes.** A unique index on (a, b, c) serves double duty as
  both a uniqueness constraint and a query index — don't create a redundant
  non-unique index on the same columns.

## Code Hygiene
- **Early return before dead computation.** If a branch exits early (e.g. MEDIA
  returns a static string), place it BEFORE computing values it won't use
  (e.g. `contextualContent`).
- **Don't mark functions `async` unless they `await`.** A function that returns
  a fire-and-forget promise but never awaits is misleading — callers may think
  it's awaitable. Use `void` return and let the promise float.
- **Remove unnecessary `as const`.** String literals assigned to typed fields
  (e.g. `type: "image"` into a `MediaType` field) don't need `as const` — TS
  infers the literal type from context.

## Documentation Sync
- **JSDoc headers must match code.** If the pipeline runs
  "classify → find user → resolve parent", the JSDoc must say that, not
  "find user → classify". Update headers when reordering code.
- **PRODUCT_SPEC step counts.** When adding pipeline steps, update the step
  count and ordering in the spec. "7 steps" → "8 steps" was stale.
- **Module-level JSDoc.** When adding new methods to a service, update the
  module header to mention the new capability.

## Testing
- **Test every type × feature combination.** Don't just test the happy path.
  For a feature like reply-to threading, test it with EVERY type:
  THOUGHT+replyTo, TODO+replyTo, QUERY+replyTo, CHAT+replyTo, MEDIA+replyTo.
- **Full object match over `objectContaining`.** Use exact assertions unless
  partial matching is intentional — `objectContaining` hides unexpected fields.
- **Assert all side effects.** If a test verifies entry creation, also verify
  the response generator received the right context. One assertion per concern,
  but cover ALL concerns.
- **Negative assertions need settle time.** `vi.waitFor` is wrong for
  "should NOT have been called" — it passes immediately. Use `setTimeout` to
  let fire-and-forget promises settle before asserting `.not.toHaveBeenCalled()`.

## Pipeline Design
- **Order operations by dependency.** If step B needs the result of step A
  (e.g. `findParentEntry` needs `userId` from `findOrCreateUser`), A must run
  first. Map dependencies before implementing.
- **Propagate context to all consumers.** If parent context exists, pass it to
  ALL relevant functions (response generator AND chat response generator), not
  just one. Check every code path that could benefit from the context.
- **Fire-and-forget should catch.** Non-critical async operations (embedding,
  storing AI response) that run without await MUST have `.catch()` handlers to
  prevent unhandled promise rejections.
