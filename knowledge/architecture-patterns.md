# Architecture Patterns

Cross-project learnings for service design, error handling, and system architecture.

## Service Layer Design

- **Optional services via env var presence.** When a feature depends on external credentials (bot token, API key, calendar service account), check env var presence at startup and skip initialization entirely when missing. Log the mode ("starting in dashboard-only mode") but don't fail. This enables deployment flexibility (bot-only, API-only, full-stack) without code changes or feature flags. <!-- Source: command-center D8, dashboard-only mode, 2026-02-15 -->
- **For single-user apps, service accounts > OAuth for external API access.** No consent screen, no token refresh, no callback URLs. The user shares their resource (calendar, drive) with the service account email. OAuth can be added later behind the same service interface.

## Async Initialization

- **Bind HTTP listener before slow async init on container platforms.** Railway, Kubernetes, and ECS health check probes expect the port to accept connections within seconds. Call `app.listen()` right after creating the app (with health/readiness routes already registered), then initialize services (bot connections, external APIs) afterward. Express/Fastify/Koa all support adding routes dynamically after the server is listening. <!-- Source: command-center fix/railway-host-bind, 2026-02-15 -->

## In-Memory State & Process Restarts

- **In-memory dedup markers don't survive restarts.** On deploy-on-push platforms (Railway, Vercel, Heroku), every deploy clears memory. Schedulers and notification systems using in-memory state (e.g., `lastSentDate`) will re-trigger on every restart. Either persist the marker to DB, or initialize defensively by checking whether the scheduled time has already passed.
- **Defensive initialization over persistence for simple cases.** If a scheduler's dedup marker is a date string, pre-set it in the constructor when the current time is past the trigger hour. Simpler than a schema change, though it can't distinguish "first startup of the day" from "restart after already sent" — acceptable when at-most-once is better than spam.

## Data Integrity

- **Pass all relevant fields at document/record creation time.** Don't assume data can be looked up later or leave fields empty for future population. The record should be complete when created — empty fields create permanent data inconsistencies that require manual data fixes.
- **Consistent treatment of related domain types across ALL calculation paths.** When multiple types share the same semantics (e.g., sick/vacation/holiday hours all count as PTO), ensure ALL paths (canonical calculation, PDF export, UI summary) treat them identically. Independent calculation paths drift apart over time — adding a new type to one path but not others is a common source of bugs.
- **Consolidate entity creation into a single shared service method.** When multiple code paths create the same entity type (e.g., entries from Telegram, web, or promotion), use one shared creation function. Independent creation paths inevitably diverge — some will miss required fields (status initialization, embeddings, metadata). This complements the "complete at creation" rule by providing a structural enforcement mechanism. <!-- Source: BUG-W007, second-brain, 2026-02-14 -->

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

## Debugging Process

- **For race conditions: list observable states.** Write out the state tuple at each step and check which intermediate states trigger effects.

---
*Sources: second-brain, lexica, command-center*
