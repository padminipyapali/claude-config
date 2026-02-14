# Testing Patterns

Cross-project learnings for testing strategy, mocking, and assertions.

## Test Strategy

- **Match test type to change type.** Route changes → integration tests. State/flow changes → flow tests. Pure logic → unit tests. Pure-function unit tests alone are NOT sufficient for route or flow changes.
- **Test every type × feature combination.** Not just the happy path. For reply-to threading: test with EVERY entry type (THOUGHT, TODO, QUERY, CHAT, MEDIA).
- **"Include tests" means flow-level tests.** Pure-function tests on extracted helpers cannot catch missing code paths.

## Assertions

- **Full object assertions, not `objectContaining`.** Partial matching hides unexpected fields unless intentional.
- **Assert ALL side effects.** If a test verifies entry creation, also verify the response generator received the right context.
- **Negative async assertions need settle time.** `vi.waitFor` is wrong for "should NOT have been called" — it passes immediately. Use `setTimeout` to let fire-and-forget promises settle before asserting `.not.toHaveBeenCalled()`.

## Mocking Pitfalls

- **pg driver type mismatches.** Mock-based tests using strings for DATE columns will pass, but pg returns JS Date at runtime. Verify pg's actual return type.
- **Shared type changes require mock updates.** After adding a field to a shared interface, grep for all `createMock*` factories.
- **Test with real services, not just mocks.** Unit tests with mocked LLM responses can't catch code fence issues. Always do a live smoke test for LLM features.

## Test Design

- **Extract guard logic into testable helpers.** Don't duplicate inline route logic in tests — extract into pure functions that routes and tests both import.
- **JSDoc on test helper factories.** `create*` test helpers should document default values and override behavior.
- **Tests use `vi.waitFor()` for async side effects.** When testing fire-and-forget patterns, wait for the side effect to complete.

---
*Sources: second-brain, lexica*
