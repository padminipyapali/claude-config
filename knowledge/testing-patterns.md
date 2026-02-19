# Testing Patterns

Cross-project learnings for testing strategy, mocking, and assertions.

## Test Strategy

- **"Include tests" means flow-level tests.** Pure-function tests on extracted helpers cannot catch missing code paths.

## Test Design

- **JSDoc on test helper factories.** `create*` test helpers should document default values and override behavior.
- **Tests use `vi.waitFor()` for async side effects.** When testing fire-and-forget patterns, wait for the side effect to complete.
- **Restore mutated `process.env` in afterEach.** Tests that `delete` or override env vars can leak state into other test files. Capture the original value in `beforeEach`, restore it in `afterEach`. <!-- Source: PR review, second-brain #148, 2026-02-17 -->
- **Verify mock targets match the production code path.** When mocking a service method for a test, trace the test's assertion back to the production code to confirm the mock intercepts the correct method. PR #159 mocked `findTodosForDate` when the tested feature used `findAllOpenTodos` — the test would have passed vacuously or failed confusingly. This is especially common when a service has multiple similar-sounding query methods (findForDate, findAllOpen, findByStatus). <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- **Assert full object shapes in test expectations, not just IDs or callbacks.** When testing structured output (inline buttons, API response objects), assert the complete object shape including labels/text, not just identifiers. Partial assertions miss label regressions and field omissions. <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- **Test boundary values explicitly for threshold/gap logic.** When testing any algorithm that splits, groups, or compares against a threshold (time gaps, count limits, size limits), always include three test cases: (1) exactly at the threshold, (2) one unit below, (3) clearly above. A test covering only "clearly above" and "clearly below" misses off-by-one bugs at the boundary. This is the minimum required for gap-grouping, session-splitting, rate-limiting, and any comparison using `>`, `>=`, `<`, or `<=`. <!-- Source: PR review, command-center #23, 2026-02-19 -->

---
*Sources: second-brain, lexica*
