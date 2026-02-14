# Architecture Patterns

Cross-project learnings for service design, error handling, and system architecture.

## Service Layer Design

- **Thin, stateless API layer.** Routes validate input and delegate to services. If a route assembles data from multiple service calls, maps/transforms results, or has conditional logic beyond auth/validation — that belongs in a service method.
- **Separate app initialization from server binding.** Tests shouldn't open ports.
- **Clean abstractions.** Each external dependency behind an interface for testability.
- **Single deployment for tightly coupled services at single-user scale.** Don't prematurely split.

## Async Initialization

- **Map the dependency graph of startup calls.** If service B can immediately fire work depending on service A, await A before starting B.
- **Async initialization ordering matters.** Anti-pattern: `telegram.start(); scheduler.start()` (scheduler fires before telegram is ready).

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
