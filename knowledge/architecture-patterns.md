# Architecture Patterns

Cross-project learnings for service design, error handling, and system architecture.

## Service Layer Design

- **Optional services via env var presence.** When a feature depends on external credentials (bot token, API key, calendar service account), check env var presence at startup and skip initialization entirely when missing. Log the mode ("starting in dashboard-only mode") but don't fail. This enables deployment flexibility (bot-only, API-only, full-stack) without code changes or feature flags. <!-- Source: command-center D8, dashboard-only mode, 2026-02-15 -->
- **For single-user apps, service accounts > OAuth for external API access.** No consent screen, no token refresh, no callback URLs. The user shares their resource (calendar, drive) with the service account email. OAuth can be added later behind the same service interface.

## Async Initialization

- **Bind HTTP listener before slow async init on container platforms.** Railway, Kubernetes, and ECS health check probes expect the port to accept connections within seconds. Call `app.listen()` right after creating the app (with health/readiness routes already registered), then initialize services (bot connections, external APIs) afterward. Express/Fastify/Koa all support adding routes dynamically after the server is listening. <!-- Source: command-center fix/railway-host-bind, 2026-02-15 -->

- **Close persistent resources (SQLite, DB pools) on ALL exit paths.** Container orchestrators send SIGTERM before SIGKILL. Add `process.on("SIGTERM", ...)` handlers that close DB connections, flush WAL journals, and exit cleanly. **Also close in `bootstrap().catch()` — if bootstrap fails after stores are initialized (e.g., during bot setup), the stores leak without explicit cleanup.** Use `try/catch` with empty catch for best-effort cleanup — the process is terminating regardless. Hoist the resource reference to module scope if it's created inside `bootstrap()`. Use optional chaining (`store?.close()`) so cleanup is safe even if the resource wasn't initialized yet. <!-- Strengthened: PR review, command-center #33, 2026-02-20 -->

## In-Memory State & Process Restarts

- **In-memory dedup markers don't survive restarts.** On deploy-on-push platforms (Railway, Vercel, Heroku), every deploy clears memory. Schedulers and notification systems using in-memory state (e.g., `lastSentDate`) will re-trigger on every restart. Either persist the marker to DB, or initialize defensively by checking whether the scheduled time has already passed.
- **Defensive initialization over persistence for simple cases.** If a scheduler's dedup marker is a date string, pre-set it in the constructor when the current time is past the trigger hour. Simpler than a schema change, though it can't distinguish "first startup of the day" from "restart after already sent" — acceptable when at-most-once is better than spam.

## Data Integrity

- **Pass all relevant fields at document/record creation time.** Don't assume data can be looked up later or leave fields empty for future population. The record should be complete when created — empty fields create permanent data inconsistencies that require manual data fixes.
- **Consistent treatment of related domain types across ALL calculation paths.** When multiple types share the same semantics (e.g., sick/vacation/holiday hours all count as PTO), ensure ALL paths (canonical calculation, PDF export, UI summary) treat them identically. Independent calculation paths drift apart over time — adding a new type to one path but not others is a common source of bugs.
- **Consolidate entity creation into a single shared service method.** When multiple code paths create the same entity type (e.g., entries from Telegram, web, or promotion), use one shared creation function. Independent creation paths inevitably diverge — some will miss required fields (status initialization, embeddings, metadata). This complements the "complete at creation" rule by providing a structural enforcement mechanism. <!-- Source: BUG-W007, second-brain, 2026-02-14 -->

## Auth & Security Boundaries

- **Scope auth fallbacks to the specific routes that need them.** When adding an alternative auth mechanism (query param token, cookie, API key header), restrict it to the exact route that requires it — never apply it globally in middleware. The temptation is to add the fallback once in shared middleware for simplicity, but this broadens the attack surface to every route. Use route path matching (`req.path`) and method checks (`req.method`) in the middleware to gate the fallback. <!-- Source: PR review, second-brain #152, 2026-02-17 -->

## Error Handling Strategy

- **Fire-and-forget needs visibility.** Log at the decision point ("split returned N items"), not just the error path. Silent success is as bad as silent failure for debugging.
- **Wrap post-stream persistence in its own try/catch.** When DB writes happen after SSE data is already sent, catch failures and emit a warning event.
- **Split try/catch for non-transactional sequential DB operations.** When two DB writes aren't wrapped in a transaction, use separate try/catch blocks so users get accurate feedback about what succeeded. If op A succeeds but op B fails, returning a generic "failed" error is misleading — the first write already committed. <!-- Source: PR review, my_mind_evolved #76, 2026-02-14 -->
- **Surface secondary operation failures as warnings, don't silently swallow.** When a multi-step creation has a primary record (entry) and a secondary record (status/metadata), don't `catch` the secondary failure and ignore it. Return a `{ result, warning? }` shape so the caller/UI can inform the user ("TODO created but status record failed"). Silent swallowing creates invisible data inconsistencies. <!-- Source: PR review, second-brain #102, 2026-02-15 -->

## Result Types & Dependency Injection

- **Discriminated unions for expected failures.** For expected failures (bad auth, invalid payload, not found), return `{ ok: true, payload }` or `{ ok: false, status, error }` rather than throwing. This makes expected failures explicit in the type system. Pattern-match on `result.ok` — no catch blocks for control flow. Reserve exceptions for truly unexpected errors. <!-- Source: second-brain DECISIONS -->
- **Context injection: config via constructor, not `process.env`.** Services receive configuration (HMAC secret, API key, DB pool) through their constructor, not by reading `process.env` directly. Keeps wiring concerns in the composition root (`server.ts`). Makes services trivially testable without env var manipulation. <!-- Source: second-brain DECISIONS -->

## Pipeline Design

- **Dedup after normalization must check both raw and cleaned text.** When a pipeline normalizes content before storage (LLM cleanup, trimming, prefix stripping), dedup checks must run on BOTH the original input AND the normalized output. Two different raw inputs can normalize to the same cleaned text, creating duplicates if only the raw text is checked. <!-- Source: PR review, second-brain #109, 2026-02-15 -->
- **Extract repeated logic from switch/if-else branches into helper functions.** When 2+ branches in a switch statement contain the same code block (e.g., creating an ACTION entry with the same field mapping), extract immediately into a helper. Copy-paste across branches is the intra-function equivalent of copy-paste across files — the branches WILL diverge as individual cases get bug fixes. Mechanical check: after writing a switch, compare each branch's body. If any two share > 3 lines of identical logic, extract. <!-- Source: PR review, second-brain #187, 2026-02-20 -->
- **Utilities copied between files in the same directory WILL diverge.** When a helper (e.g., `getDayLabel`, `formatRelativeDate`) is duplicated rather than extracted, the two copies accumulate independent fixes and edge-case handling. Extract immediately on first duplication into a shared module. If you discover two copies differ (e.g., `"3 Days Ago"` vs `"Mon, Feb 17"`), treat it as a bug — audit which behavior is correct, unify, and delete the copy. <!-- Source: PR review, command-center #23, 2026-02-19 -->
- **Fallback/legacy paths must match primary path semantics exactly.** When a primary code path distinguishes sentinel values (e.g., `null` vs `undefined` for "no date" vs "run extraction"), the fallback path must preserve the same distinction — don't use falsy coercion (`if (!x)`) that collapses them. Similarly, when the primary path passes explicit parameters to a shared function (e.g., `{ channel: "IN_APP" }`), the fallback must pass them too — don't rely on defaults in one path but not the other. Divergence between primary and fallback paths is the #1 source of subtle bugs when consolidating code paths behind a service. <!-- Source: PR review, second-brain #197, 2026-02-20 -->
- **When capping API results, always surface truncation to the caller.** If a service limits results to N items (e.g., 100 per repo), the response must include a flag or count indicating truncation: `{ items, truncated: items.length === MAX }`. Without it, UIs silently show incomplete data with no way to warn users. When adding truncation detection to a new service, grep for sibling services — the pattern should be consistent across the codebase. <!-- Source: PR review, command-center #23, 2026-02-19 -->

## Sub-Agent Delegation

- **Always include adversarial review instructions for delegated agents.** Agents follow feature correctness but skip security/robustness review unless explicitly prompted.
- **Parallel agents must use separate branches/worktrees.** Shared checkouts cause "file modified since read" errors.
- **Separate fixer and reviewer agents.** The agent that wrote a `catch-all return []` won't question its own code. Use two-agent pipeline: fixer commits, then reviewer reviews.
- **When concurrent agents may be active in a repo, use a Task agent with `bypassPermissions` to apply all edits atomically.** Concurrent agents running builds, linters, or formatters can revert uncommitted file edits between individual Edit tool calls. Delegating all changes to a single Task agent that applies edits + builds + tests in one burst prevents interference. This is a workaround — the real fix is to always run the CLAUDE.md repo conflict detection protocol before starting work. <!-- Source: second-brain feat/calendar-command, 2026-02-16 -->

## Planning Discipline

- **State reset effects must re-populate for ALL paths.** When `useEffect` clears state on dependency change, every path that sets the dependency must ensure re-population.
- **Cross-channel regression testing.** When modifying shared data formats consumed by multiple output channels (web, Telegram, email), verify ALL channels still work. Same data, different display constraints — web can render rich HTML while Telegram has a 4096-char text limit. Add this to the PR checklist for multi-channel apps. <!-- Source: BUG-022, second-brain #101, 2026-02-15 -->

## Scheduling & At-Most-Once Delivery

- **State update BEFORE side effect for at-most-once delivery.** In schedulers that deliver notifications, update persistent state (e.g., `lastSentDate`) BEFORE the side effect (sending the message). If the server crashes after marking but before delivery, the user misses one notification rather than getting duplicates on every restart. At-most-once > at-least-once-with-spam for non-critical notifications. <!-- Source: BUG-T017, second-brain -->

## Shell & Data Pipeline Pitfalls

- **Off-by-one field indexes when prepending columns in awk pipelines.** When an awk script prepends a new field (e.g., `print session "|" $0`), all downstream awk commands that reference the original fields must shift their indexes by +1. If the original line had `timestamp|type|repo` as `$1|$2|$3`, after prepending session it becomes `session|timestamp|type|repo` = `$1|$2|$3|$4`. Missing this shift causes type-checking conditions (like `$2 == "commit"`) to compare against the wrong field (timestamp instead of type), silently producing zero matches and empty output. **Mitigation:** Comment the field layout at the top of each pipeline stage (`# Format: session|timestamp|type|repo|hash|subject`), and grep-verify one record before building the full pipeline. <!-- Source: sessions off-by-one bug, 2026-02-19 -->
- **`<<<` (here-string) appends a trailing newline.** In bash, `func <<< "$var"` feeds `$var` plus `\n` to stdin. If the function encodes stdin verbatim (e.g., `json.dumps(sys.stdin.read())`), the output includes the newline as data. Use `printf '%s' "$var" | func` instead to avoid the invisible trailing newline. This is especially insidious with JSON encoding — `json.dumps("hello\n")` produces `"hello\n"` which looks correct until it breaks downstream parsing. <!-- Source: sessions json_str bug, 2026-02-19 -->

## Pattern Consistency

- **When following an existing pattern, implement it fully or don't start.** If a codebase has cursor-based pagination implemented for list types A and B (with `loadMore` functions, cursor state, and UI triggers), adding list type C must include the same pagination support. Capturing the cursor from the API response without wiring the "load more" behavior creates dead state and gives the false impression that pagination is supported. Either implement the full pattern (state + load function + UI trigger) or explicitly skip cursor capture with a comment explaining why. <!-- Source: PR review, second-brain #164, 2026-02-19 -->

## Debugging Process

- **For race conditions: list observable states.** Write out the state tuple at each step and check which intermediate states trigger effects.

---
*Sources: second-brain, lexica, command-center*
