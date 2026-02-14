# Lexica Project Memory

## Workflow Preferences

### Review-Fix: Critically Evaluate Before Fixing
- **Don't blindly fix all automated reviewer comments.** When running /review-fix, first evaluate whether each comment is actually correct and worth fixing. CodeRabbit (and similar tools) frequently flag non-issues — nitpicks on docs wording, overly conservative null guards on typed fields, style suggestions that don't improve the code. Categorize each comment as **must fix** (real bug, security, correctness), **should fix** (valid improvement), or **disagree** (explain why and skip). Only fix comments that pass evaluation. Push back on bad suggestions rather than cargo-culting them.

## Learnings from Code Reviews

### React Hooks Ordering
- **Always place hooks before early returns**: `useMemo`, `useCallback`, `useEffect`, `useState`, and all other hooks must be called unconditionally at the top of the component, before any `if (...) return` early exits. React requires hooks to run in the same order on every render. When adding a new hook to an existing component with early returns, place it alongside the other hooks — never after the guard clauses.

### React Native / XHR Patterns
- **Unmount guards on ALL XHR handlers — initial AND retry**: Every `onprogress`, `onload`, and `onerror` handler must check `if (!isMountedRef.current) return;` as its first line — not just the retry handlers, but also the initial request's handlers. The same applies to every `.then`/`.catch` callback. Abort-on-unmount is not sufficient because the abort races with handler invocation. Reviewers consistently flag missing guards on initial handlers when only retry handlers are guarded.
- **Explicit logout on auth failure**: Any path where a token refresh fails or a retry returns 401 must call `logout()` — not just surface an error. Stale auth state leaves the app stuck.
- **Abort in-flight XHR on session/context change**: When a session ID changes, abort any active XHR before resetting state to prevent stale data from a previous request leaking into the new session.

### Prompt Injection / AI Safety
- **Escape XML delimiters in user content**: When interpolating user text into XML-tagged AI prompts, escape `<`/`>` with `&lt;`/`&gt;` to prevent users from injecting closing/opening tags that manipulate prompt structure.
- **Escape ALL user-sourced strings in prompts, including DB-stored values**: Word names, definitions, and example sentences stored in DB are still user-provided. Escape them when interpolating into prompt strings (welcome instructions, word bank layers). Reviewers flag this even when data comes from the DB rather than raw request input.

### DRY / Shared Code
- **Import constants from `@lexica/shared`**: Never duplicate shared constants (e.g., `MASTERY_STAGES`) in consuming packages. Always import from the shared package. Reviewers consistently flag this.
- **Use precise type assertions**: Prefer `as MasteryStage` over `as any` when the type is known. Reviewers flag `as any` even in non-critical paths.

### Fire-and-Forget Patterns
- **Non-blocking SSE writes need `.catch()`**: When an SSE `writeSSE()` call is intentionally not awaited (e.g., `session_words` event sent before streaming starts), it must have `.catch(() => {})` to satisfy the fire-and-forget rule.

### Code Style
- **No `async` without `await`**: Do not mark functions `async` unless they contain an `await` expression. If the function uses `.then()`/`.catch()` chains instead of `await`, it should not be `async`. An `async` function without `await` silently wraps the return in a `Promise`, changing the type signature (e.g., `() => void` becomes `() => Promise<void>`) without adding value. Reviewers flag this per CLAUDE.md rules.

### Deduplication
- **Case-insensitive dedup for word-based data**: When building UI lists from AI-generated word arrays, use a `Set<string>` with `.toLowerCase()` normalization to prevent duplicates caused by casing differences.

## Learnings from Bug RCA (Chat UI Bugs — 2026-02-12)

### React Native FlatList
- **Always pass `extraData` for external state**: FlatList memoizes `renderItem` aggressively. Any state used inside `renderItem` that isn't part of the `data` array MUST be passed via `extraData`, or items won't re-render when that state changes. Common gotcha: word bank loads asynchronously via SSE, but FlatList doesn't know to re-render existing items.

### AI Model Output Validation
- **Filter AI output against source of truth before sending to client**: When an AI model (e.g., Haiku) returns structured data (evaluations, word lists), always validate/filter against the authoritative source (word bank, user data) server-side. Don't trust the model to stay within scope — it may evaluate or reference items not in the input set.

### UI Content Display
- **Don't hardcode line limits on variable-length content**: Avoid `numberOfLines` or similar truncation on content whose length varies (e.g., AI feedback text). If truncation is needed for layout, make it expandable (tap to expand) rather than silently cutting off.

## Learnings from PR Review (Welcome Message + Word Bank Bar — 2026-02-12)

### SSE Event Parsing
- **Defensive type checks on SSE event fields**: Never use `event.text as string` or `event.message as string` on parsed SSE data. Always guard with `typeof event.field === 'string'` before using. Applies to ALL fields from parsed JSON events.

### React useEffect Patterns
- **Consolidate related effects sharing dependencies**: When two `useEffect` hooks depend on the same value and one must run before the other, merge into a single effect. Implicit ordering between separate effects is fragile.

### API Response Null Guards
- **Always `?? []` when mapping API response arrays**: Even when TypeScript says the field is required, add a null guard before `.map()`. Servers can return unexpected shapes.

### Testing
- **Extract guard logic into testable helpers**: Don't duplicate inline route logic in tests. Extract into pure functions that routes and tests both import.

### Accessibility
- **Always add a11y props to interactive RN components**: `Pressable` needs `accessibilityRole="button"` and `accessibilityLabel`. Reviewers flag missing a11y on new interactive components.

### Resilience
- **Wrap post-stream persistence in its own try/catch**: When DB writes happen after SSE data is already sent, wrap in try/catch. On failure, emit a warning event and still send `[DONE]`.

### Structured Logging
- **Log error type/name, never error.message**: `error.message` can contain user content (DB params, persisted text). Use `{ sessionId, errorType: error.name }` instead. Reviewers flag `error.message` in logs even when it seems harmless.

### Type Precision at DB Boundaries
- **Cast DB `string` fields to shared union types at call sites**: When DB query types use `string` (e.g., `WordRow.mastery_stage`) but the value is constrained by a DB CHECK to match a TypeScript union (e.g., `MasteryStage`), cast with `as MasteryStage` at the call site with a comment explaining the CHECK constraint guarantees the value. Don't weaken shared interface types to `string` to match the DB layer.

## Learnings from Bug RCA (Session Resume Bug — 2026-02-12)

### Planning
- **Always trace ALL entry points in plans.** The resume bug happened because the plan only traced "new session". Ask: "what happens when `isNewSession` is false?"
- **State reset effects must have re-population for ALL paths.** When `useEffect` clears state on dependency change, every code path that sets the dependency must ensure re-population.

### Testing
- **"Include tests" means flow-level tests, not just unit tests on extracted helpers.** Pure-function tests cannot catch missing code paths. Route changes need integration tests (`app.request()`), state/flow changes need flow tests exercising branching logic.

## Learnings from PR Review (Session Resume Fix — PR #7, 2026-02-12)

### Async State Race Conditions
- **Merge async-loaded data with existing state, don't replace conditionally.** When loading data async (e.g., message history), never use `prev.length === 0 ? loaded : prev` — this drops loaded data if the user acts fast. Use a dedup merge: `[...loaded, ...prev.filter(m => !seen.has(m.id))]`.

### Defensive Coding (Reinforced)
- **Guard API response shape before destructuring.** Even with TypeScript generics on `api.get<T>()`, always check `Array.isArray()` before `.filter()/.map()` on response arrays. The type assertion doesn't validate runtime shape.

## Learnings from Bug RCA (Restart Race Condition — 2026-02-12)

### Zustand + React Effects: Atomic State Transitions
- **Never create an intermediate state that matches an auto-start effect's trigger.** If an effect watches for `sessionId=null && isCreating=false` to auto-call `startSession()`, then `restartSession` MUST NOT set `sessionId=null` in one `set()` and `isCreating=true` in a separate call. The effect sees the gap and races. Always set all guard-relevant fields in a single `set()`.
- **When bypassing a re-entrancy guard, inline the logic.** `restartSession` tried to reuse `startSession()` after clearing state, but `startSession` has an `if (isCreating) return null` guard. In the race, the effect's call wins the guard, and the intended call returns null — setting neither sessionId nor error. If you need to call a guarded function after atomically setting its guard flag, you must inline the guarded body instead of calling through the guard.

### Debugging Process (Meta)
- **Ask for exact repro steps immediately.** Don't speculate through 15 theories when the user is available. "What did you do, what did you see?" narrows the search space faster than code analysis.
- **Don't dismiss a theory based on framework internals you aren't 100% certain about.** I identified the race condition early but talked myself out of it by reasoning about React 18/19 batching guarantees. The correct framing is: "the code should never produce an invalid intermediate state, regardless of batching behavior." Design for correctness, don't rely on scheduler implementation details.
- **When analyzing race conditions, list the states and check which ones are observable by effects.** Write out the state tuple `(sessionId, isCreating, error)` at each step and check if any intermediate tuple triggers an effect. This is faster than reasoning about React render timing.
