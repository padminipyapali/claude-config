# Post-Mortem: Leaflet PR #8

**Title:** feat: end-to-end vertical slice -- topic input, Claude generation, booklet display
**Branch:** feat/pr1-scaffold -> main | **Author:** padminipyapali
**Merged:** 2026-03-09 | **Duration:** 5.2 hours
**Size:** +6755 -0 across 15 files, 8 commits (squash-merged)

## Local Review (pre-push)

- **CodeRabbit:** not run locally (no .coderabbit.yaml yet)
- **Adversarial:** abbreviated (first PR, no existing code baseline)
- **Internal review (critic):** 10 issues found, 10 fixed (3 critical, 1 high, 4 medium, 2 low)
- **Shift-left rate:** 14% (1 pre-push fix commit / 7 substantive commits). Low because steps 4a, 4c, 4d were skipped or abbreviated.

## Step Compliance

- **Steps run:** 1 (plan), 2a (implement), 3 (test/Playwright), 4b (internal review), 5 (push/PR)
- **Steps skipped:** 2b (hardening), 4a (simplify -- first PR), 4c (CodeRabbit -- no config), 4d (adversarial -- abbreviated)
- **Compliance rate:** 5/9 = 55.6%
- **Skip assessment:** bad -- 18 of 19 post-push CodeRabbit findings would have been caught by the skipped steps (4c CodeRabbit, 4d adversarial). The abbreviated adversarial review missed 9 issues that the full checklist covers.

## Step Timing

Not tracked for this PR (first PR, no orchestrator timing instrumentation).

## Review Friction (post-push)

- **Review rounds:** 5 (5 CHANGES_REQUESTED from CodeRabbit bot before squash-merge)
- **Comments:** 19 inline, 0 general (all from coderabbitai[bot])
- **Categories:** security: 3, correctness: 14, architecture: 1, documentation: 1
- **Timeline:** created -> first review: 10m | first review -> merge: 5.0h | total: 5.2h
- **Self-merge:** Yes, with bot-only review (no human reviewer)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 64% (9/14 actionable findings were in the adversarial checklist)
- **Covered but missed (9):**
  - JSON body size cap (Tier 1: input validation on routes)
  - Zod request schema validation (Tier 1: input validation)
  - Error leak prevention (Tier 1: error handling, sanitized responses)
  - Non-empty string schema (Tier 1: input validation, whitespace-only strings)
  - AbortController on disconnect (Tier 1: async error handling)
  - JSON error middleware (Tier 1: error handling middleware)
  - Unsplash rate limiter (Tier 1: rate limiting on public endpoints)
  - Robust fence stripping (Tier 3: LLM output validation)
  - Silence APIUserAbortError (Tier 1: expected vs unexpected errors)
- **Not covered (5 -- potential checklist additions):**
  - @types/express version mismatch (dependency version compatibility)
  - prefers-reduced-motion (a11y: motion sensitivity)
  - autoFocus removal (a11y: focus management)
  - Stale abort vs timeout (abort signal lifecycle management)
  - Unsplash fetch timeout (external API timeout)

## Fix-Up Metrics

- **Post-merge fix rate:** 0% (no post-merge fix PRs)
- **Pre-merge catch rate by step:**
  - 4a (simplify): 0 fixes (skipped)
  - 4b (internal): 1 fix commit (10 issues: abort signal, Zod validation, a11y, error handling)
  - 4c (CodeRabbit): 0 fixes (skipped locally)
  - 4d (adversarial): 0 fixes (abbreviated)
  - post-push: 5 fix commits (18 issues across 5 CodeRabbit review rounds)
- **Pre-merge iteration count:** 5 (high friction -- 5 CHANGES_REQUESTED rounds)
- **Fix-up taxonomy:**
  - validation: 3 (Zod schema, non-empty string, JSON body cap)
  - a11y: 3 (prefers-reduced-motion, autoFocus, focus-visible)
  - defensive-coding: 4 (rate limiter, timeout, abort on disconnect, error leak)
  - correctness: 4 (@types/express, stale abort, fence stripping, silence abort errors)
  - infrastructure: 1 (trigger CodeRabbit review marker commit)
- **Legacy fix-up ratio:** 75% (6 fix / 8 total commits)

## Planning Quality

- **Description:** complete (Summary + Test Plan + Local Review sections)
- **Scope:** clean (single vertical slice, no scope creep)
- **Branch lifetime:** 5.2 hours
- **Planning checklist:** partial -- entry points listed, but no Performance & Cost section

## Code Quality Signals

- **Recurring issues:** correctness (14 comments) dominated. Input validation and defensive coding were the most common fix categories (7 of 14 substantive fixes).
- **New patterns captured:** LLM fence stripping robustness, APIUserAbortError handling, Express JSON parse error middleware -- all already captured in knowledge files during the session.

## Process Efficiency

- **Automation opportunities:**
  - A .coderabbit.yaml should have been set up in the project-setup PR so CodeRabbit ran locally (step 4c) before push
  - The full adversarial review (step 4d) would have caught 9/14 issues pre-push
  - A Tier 0 automated grep for `express.json()` without size limit would catch the body size cap issue
- **Iteration:** high friction (5 rounds). All friction was CodeRabbit bot rounds that could have been pre-empted by local CodeRabbit + full adversarial review.
- **CI status:** TypeScript passes. No test suite (deferred -- noted as process gap).

## Key Findings

1. **Skipping steps 4c/4d on a first PR is costly.** The "first PR, no config" rationale for skipping CodeRabbit and abbreviating adversarial review resulted in 5 post-push review rounds and 18 findings. The project-setup PR should have installed .coderabbit.yaml.

2. **No tests is a significant process gap.** The PR body notes "No test suite yet" and deferred test items. For a 6755-line PR with server-side API integration, unit tests for the validation layer and integration tests for the proxy endpoint would have caught several issues (Zod schema completeness, fence stripping edge cases).

3. **Bot-only review with 5 rounds inflates timeline.** 5 hours elapsed, mostly waiting for CodeRabbit rounds. Running CodeRabbit locally (even without .coderabbit.yaml, the CLI works) would have compressed this to 1-2 rounds.

4. **64% adversarial catch potential confirms the checklist works.** 9 of 14 findings were already in the adversarial review checklist. The abbreviated run missed them all. This is direct evidence that skipping step 4d has measurable cost.

## Deferred Items

- Health check / graceful shutdown (1 CodeRabbit finding) -> deferred to PR #3
- Test suite setup -> deferred (no PR number yet)

## Recommendations

1. **Never skip step 4c/4d on scaffold PRs.** Scaffold PRs have the highest surface area and benefit most from full review. If .coderabbit.yaml is missing, set it up as part of the PR or run CodeRabbit CLI without config.
2. **Add tests in PR #2 or #3.** At minimum: Zod schema validation tests, fence stripping edge cases, proxy endpoint integration tests.
3. **Add Tier 0 grep for Express body size limits.** `express.json()` without `{ limit: }` should be an automated catch.
4. **Add a11y motion/focus checks to the adversarial checklist.** prefers-reduced-motion and autoFocus are not currently covered.
