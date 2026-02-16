# Testing Patterns

Cross-project learnings for testing strategy, mocking, and assertions.

## Test Strategy

- **"Include tests" means flow-level tests.** Pure-function tests on extracted helpers cannot catch missing code paths.

## Test Design

- **JSDoc on test helper factories.** `create*` test helpers should document default values and override behavior.
- **Tests use `vi.waitFor()` for async side effects.** When testing fire-and-forget patterns, wait for the side effect to complete.

---
*Sources: second-brain, lexica*
