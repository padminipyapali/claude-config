# Testing Patterns

Cross-project learnings for testing strategy, mocking, and assertions.

## Test Strategy

- **"Include tests" means flow-level tests.** Pure-function tests on extracted helpers cannot catch missing code paths.

## Test Design

- **JSDoc on test helper factories.** `create*` test helpers should document default values and override behavior.
- **Tests use `vi.waitFor()` for async side effects.** When testing fire-and-forget patterns (`.catch()` call sites), the fire-and-forget promise resolves asynchronously even when mocks are synchronous. Assertions on those calls need a microtask flush before checking: `await new Promise(r => setTimeout(r, 0))`. Without the flush, the assertion runs before the mock is called, producing false negatives. `vi.waitFor()` is also acceptable but less explicit about the cause. This applies to any code that calls an async function without `await` (fire-and-forget) — the test must yield to the event loop before asserting on the mock. <!-- Strengthened: PR review, second-brain #246, 2026-02-25 -->
- **Restore mutated `process.env` in afterEach.** Tests that `delete` or override env vars can leak state into other test files. Capture the original value in `beforeEach`, restore it in `afterEach`. <!-- Source: PR review, second-brain #148, 2026-02-17 -->
- **Verify mock targets match the production code path.** When mocking a service method for a test, trace the test's assertion back to the production code to confirm the mock intercepts the correct method. PR #159 mocked `findTodosForDate` when the tested feature used `findAllOpenTodos` — the test would have passed vacuously or failed confusingly. This is especially common when a service has multiple similar-sounding query methods (findForDate, findAllOpen, findByStatus). <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- **Assert full object shapes in test expectations, not just IDs or callbacks.** When testing structured output (inline buttons, API response objects), assert the complete object shape including labels/text, not just identifiers. Partial assertions miss label regressions and field omissions. <!-- Source: post-mortem, second-brain #159, 2026-02-19 -->
- **Test boundary values explicitly for threshold/gap logic.** When testing any algorithm that splits, groups, or compares against a threshold (time gaps, count limits, size limits), always include three test cases: (1) exactly at the threshold, (2) one unit below, (3) clearly above. A test covering only "clearly above" and "clearly below" misses off-by-one bugs at the boundary. This is the minimum required for gap-grouping, session-splitting, rate-limiting, and any comparison using `>`, `>=`, `<`, or `<=`. <!-- Source: PR review, command-center #23, 2026-02-19 -->

- **Test fixture must omit the property being tested for defaults.** When testing "defaults X to Y", the test fixture must NOT include property X. If `makeSession()` already sets `source: "agent"`, a test titled "defaults source to agent" is tautological — it tests the fixture, not the code. Delete the property from the fixture before calling the function under test so the defaulting logic is actually exercised. <!-- Source: PR review, command-center #34, 2026-02-21 -->

- **Fake timers with `shouldAdvanceTime: true` for React Testing Library.** Vitest fake timers (`vi.useFakeTimers()`) hang indefinitely with `@testing-library/react` because RTL uses `setTimeout`/`setInterval` internally for `waitFor` and cleanup. Pass `vi.useFakeTimers({ shouldAdvanceTime: true })` to let RTL's internal timers progress while still controlling time in your tests. Always pair with `vi.useRealTimers()` in `afterEach`. Without `shouldAdvanceTime`, tests that render React components with fake timers will freeze. <!-- Source: PR review, second-brain #186, 2026-02-19 -->

- **Test mutually exclusive UI states with both PRESENCE and ABSENCE assertions.** When testing UI states that replace one element with another (e.g., "Explore button" replaced by "badge when research is complete"), test cases must assert BOTH the presence of the new element AND the absence of the old one. Testing only presence misses cases where both render simultaneously. Pattern: assert `getByRole("button", { name: /explore/i })` fails (or use `queryByRole`), AND assert `getByText(/ready/i)` succeeds. This applies to any conditional UI branch where two elements are mutually exclusive (loading spinner vs. content, edit mode vs. view mode, error state vs. success state). <!-- Source: CodeRabbit review, second-brain #213, 2026-02-23 -->

- **Test every error path in try/catch blocks, not just the primary one.** When a try block contains multiple `await` calls (e.g., `findUser()` then `linkUser()`), each can fail independently. A test for `findUser()` throwing doesn't cover `linkUser()` throwing -- both reach the same catch block but via different code paths. Write a separate test for each `await` that can throw, mocking the preceding calls to succeed and the target call to reject. This is especially important for linking/creation flows where the first call is a lookup and the second is a write. <!-- Source: PR review, second-brain #234, 2026-02-25 -->

- **Use specific patterns in negative assertions, not short substrings.** `not.toContain("View")` will break when any unrelated text contains the word "View" (e.g., "Weekly Review"). Use `not.toMatch(/View \d+ more in dashboard/)` or assert absence of the specific element/pattern you care about. The shorter the negative assertion string, the more likely it matches unintended content. <!-- Source: PR review, second-brain #276, 2026-02-26 -->

## Async Test Patterns

- **Negative async assertions need settle time.** Polling helpers like `waitFor` pass immediately for negative assertions ("should NOT have been called") because the condition is true from the start. Use an explicit timeout to let promises settle before asserting: `await new Promise(r => setTimeout(r, 50)); expect(mock).not.toHaveBeenCalled();`. Without the settle delay, the assertion passes vacuously even if the mock IS called a microtask later.

## Mocking Pitfalls

- **`vi.doMock` does not affect already-resolved static imports.** `vi.doMock()` only applies to subsequent dynamic `import()` calls, not modules already loaded via static `import` at the top of the file. If you import `Foo` statically and then `vi.doMock("foo-module", ...)`, the imported `Foo` still points to the real module. Either use `vi.mock()` (hoisted to file top) or manually override the dependency on the instance (e.g., `(obj as any).client = mockClient`). Dead `vi.doMock` blocks are common — they appear to work only because a manual override elsewhere does the real mocking. <!-- Source: PR review, command-center #40, 2026-02-27 -->

## Test Cleanup

- **`vi.restoreAllMocks()` belongs in `afterEach`, never inside individual tests.** Placing `vi.restoreAllMocks()` at the end of a specific test is fragile — if the test fails or is skipped, mocks leak into subsequent tests. Move to `afterEach(() => { vi.restoreAllMocks(); })`. Same applies to `vi.useRealTimers()`, `vi.unstubAllEnvs()`, and any state restoration. General rule: cleanup that undoes test-specific mutations goes in `afterEach`, not in the test body. <!-- Source: PR review, second-brain #256, 2026-02-25 -->

## Mock Data Type Safety

- **Match exact types in mock data — `vi.fn()` bypasses type checking.** When constructing mock return values (e.g., `vi.mocked(service.query).mockResolvedValue({...})`), match the exact TypeScript type for every field. Common trap: `completedAt: new Date().toISOString()` produces a `string`, but the interface declares `completedAt: Date`. Tests pass because `vi.fn()` and `as unknown as` casts bypass compile-time checking, but the mock shape silently diverges from production data. If the implementation later accesses `.getTime()` or other Date methods, the test will fail with a confusing runtime error instead of catching the mismatch early. <!-- Source: PR review, second-brain #199, 2026-02-21 -->

---
*Sources: second-brain, lexica*
