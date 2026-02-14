# Architecture Patterns

Cross-project learnings for service design, error handling, and system architecture.

## Service Layer Design

- **Thin, stateless API layer.** Routes validate input and delegate to services. If a route assembles data from multiple service calls, maps/transforms results, or has conditional logic beyond auth/validation — that belongs in a service method.
- **Separate app initialization from server binding.** Tests shouldn't open ports.
- **Clean abstractions.** Each external dependency behind an interface for testability.
- **Single deployment for tightly coupled services at single-user scale.** Don't prematurely split.
- **For single-user apps, service accounts > OAuth for external API access.** No consent screen, no token refresh, no callback URLs. The user shares their resource (calendar, drive) with the service account email. OAuth can be added later behind the same service interface.

## Async Initialization

- **Map the dependency graph of startup calls.** If service B can immediately fire work depending on service A, await A before starting B.
- **Async initialization ordering matters.** Anti-pattern: `telegram.start(); scheduler.start()` (scheduler fires before telegram is ready).

## In-Memory State & Process Restarts

- **In-memory dedup markers don't survive restarts.** On deploy-on-push platforms (Railway, Vercel, Heroku), every deploy clears memory. Schedulers and notification systems using in-memory state (e.g., `lastSentDate`) will re-trigger on every restart. Either persist the marker to DB, or initialize defensively by checking whether the scheduled time has already passed.
- **Defensive initialization over persistence for simple cases.** If a scheduler's dedup marker is a date string, pre-set it in the constructor when the current time is past the trigger hour. Simpler than a schema change, though it can't distinguish "first startup of the day" from "restart after already sent" — acceptable when at-most-once is better than spam.

## Data Integrity

- **Pass all relevant fields at document/record creation time.** Don't assume data can be looked up later or leave fields empty for future population. The record should be complete when created — empty fields create permanent data inconsistencies that require manual data fixes.
- **Consistent treatment of related domain types across ALL calculation paths.** When multiple types share the same semantics (e.g., sick/vacation/holiday hours all count as PTO), ensure ALL paths (canonical calculation, PDF export, UI summary) treat them identically. Independent calculation paths drift apart over time — adding a new type to one path but not others is a common source of bugs.

## Error Handling Strategy

- **Graceful degradation at every layer.** Independent error handling around each operation.
- **Global error handlers on long-running services.** Per-request handling is necessary but not sufficient — add `process.on('uncaughtException')` and `process.on('unhandledRejection')`.
- **Fire-and-forget needs visibility.** Log at the decision point ("split returned N items"), not just the error path. Silent success is as bad as silent failure for debugging.
- **Wrap post-stream persistence in its own try/catch.** When DB writes happen after SSE data is already sent, catch failures and emit a warning event.

## Pipeline Design

- **Order operations by dependency.** Map dependencies before implementing — if step B needs step A's result, A runs first.
- **Propagate context to ALL consumers.** If parent context exists, pass it to ALL functions that could use it, not just one.
- **Decouple processing from external responses.** Respond to webhooks/requests immediately, process asynchronously.

## Sub-Agent Delegation

- **Always include adversarial review instructions for delegated agents.** Agents follow feature correctness but skip security/robustness review unless explicitly prompted.
- **Parallel agents must use separate branches/worktrees.** Shared checkouts cause "file modified since read" errors.
- **Separate fixer and reviewer agents.** The agent that wrote a `catch-all return []` won't question its own code. Use two-agent pipeline: fixer commits, then reviewer reviews.

## Planning Discipline

- **Always trace ALL entry points.** New vs resume, create vs update, empty vs populated state. The resume bug happened because the plan only traced "new session."
- **State reset effects must re-populate for ALL paths.** When `useEffect` clears state on dependency change, every path that sets the dependency must ensure re-population.
- **Adversarial-review plans before presenting them.** The first plan is often not the best. Run cost/risk/tradeoff analysis.
- **Performance & Cost Impact section in every plan.** Cover: latency, API call costs, DB query load, code path frequency, mitigations.

## Debugging Process

- **Ask for exact repro steps immediately.** Don't speculate through theories when the user is available.
- **Don't dismiss theories based on framework internals you aren't certain about.** Design for correctness regardless of scheduler/batching behavior.
- **For race conditions: list observable states.** Write out the state tuple at each step and check which intermediate states trigger effects.

---
*Sources: second-brain, lexica, command-center*
