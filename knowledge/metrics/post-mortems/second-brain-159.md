# Post-Mortem: second-brain PR #159 — Add IN_PROGRESS status for TODOs

**Branch:** feat/todo-in-progress -> main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-02-19T15:51:28Z | **Merged:** 2026-02-19T19:15:25Z
**Duration:** 3.40 hours
**Size:** +598 -289 across 28 files, 5 commits

## Scope

Large cross-cutting feature adding three-state TODO lifecycle (OPEN -> IN_PROGRESS -> DONE). Touched DB migration, shared types, server services, API routes, Telegram inline keyboards, web dashboard (hooks + components + CSS), and tests.

## Local Review (Pre-Push)

- **CodeRabbit local:** 3 issues found, 2 fixed (1 iteration). 1 intentionally skipped (user ownership validation -- scope expansion for single-user app).
- **Adversarial review local:** 6 issues found, 5 fixed. Issues fixed: trigger gap for DONE->IN_PROGRESS, missing ts.started_at in thread query, JSDoc update, loadMoreOpen sort, PRODUCT_SPEC.md update. 1 informational skipped (test coverage for new API params).
- **CI status:** All passed (745 tests, build clean).
- **Total pre-push issues caught:** 9 (3 CodeRabbit + 6 adversarial)

## Post-Push Review (CodeRabbit)

### Round 1 (review_id: 3827820971, CHANGES_REQUESTED)
5 inline comments:
1. **[Major/Security]** Scope TODO status updates to requesting user (telegram.ts) -- Intentionally deferred as single-user app.
2. **[Trivial/Testing]** Add startedAt: null for test fixture completeness (integration.test.ts)
3. **[Trivial/Correctness]** Add fallback label for empty button text (message-processor.ts)
4. **[Minor/Security]** Reject non-string todoStatus query params (api.ts) -- Fixed.
5. **[Trivial/Testing]** Make test helper accept status param for IN_PROGRESS coverage (morning-brief-scheduler.test.ts)

### Round 2 (review_id: 3827881584, CHANGES_REQUESTED)
3 inline comments:
6. **[Minor/Testing]** Strengthen inline button assertions with full object shape (message-processor.test.ts) -- Fixed.
7. **[Critical/Correctness]** Test mocks wrong service method - findTodosForDate vs findAllOpenTodos (morning-brief-scheduler.test.ts) -- Fixed.
8. **[Minor/Correctness]** fetchTodos passes comma-separated string instead of array (hooks.ts) -- Fixed.

### Round 3 (COMMENTED)
No new inline comments. Review acknowledged fixes.

## Comment Categories
- Security: 2 (user scoping, input validation)
- Correctness: 3 (empty label, wrong mock target, type mismatch)
- Testing: 3 (fixture shape, assertion completeness, test design)
- Architecture: 0, Style: 0, Performance: 0, Documentation: 0, Other: 0

## Commit Classification
1. "Add IN_PROGRESS status for TODOs with inline keyboards and web UI" -- **feature**
2. "Address PR review: input validation, test coverage, and sort consiste..." -- **fix**
3. "Update adversarial review marker for PR review fixes." -- **fix** (marker)
4. "Update adversarial review marker." -- **fix** (marker)
5. "Address PR review: fix test mocks, full assertions, and loadMoreOpen..." -- **fix**

Fix-up ratio: 4/5 = 0.80 (80%). Substantive fix-up ratio (excluding markers): 2/5 = 0.40 (40%).

## Adversarial Review Effectiveness

### Covered but missed (in checklist, not caught locally):
- **Input validation at boundaries (Tier 2):** Non-string todoStatus query param not rejected.
- **Test assertion completeness (Tier 3):** Inline button tests asserted only callbackData, not labels.
- **Test mock correctness (NEW):** Mocked wrong service method for tested code path.
- **Type consistency (Tier 4):** fetchTodos called with comma-string instead of array.

### Not covered (new categories for checklist):
- Test mock target verification -- ADDED to Tier 3.
- Full object shape assertions on structured output -- ADDED to Tier 3.

### Pre-push catch potential: 67% (4 of 6 substantive issues were in scope of the checklist).

### Shift-left analysis:
- Issues caught pre-push: 9 (3 CodeRabbit local + 6 adversarial)
- Issues caught post-push: 8 (all CodeRabbit)
- Total: 17
- Shift-left rate: 53% (9/17 caught locally)

## Planning Quality
- **Description:** Complete (Summary, Test Plan, Local Review sections present).
- **Scope:** Clean -- no redesign commits, no scope creep.
- **Branch lifetime:** 3.40 hours (well under 48h threshold).
- **Planning checklist:** Entry points enumerated, test plan detailed, performance section not explicitly present but change is UI-level with no new external API calls.

## Step Compliance
All 8 steps run (1, 2, 3, 4a, 4b, 4c, 4d, 5). Compliance rate: 100%.
Skip assessment: n/a (no steps skipped).

## Process Efficiency
- **Iteration:** 2 rounds = normal. Consistent with expectation for large cross-cutting PRs.
- **Self-merge:** Yes, self-merged after addressing both rounds of CodeRabbit findings.
- **Automation opportunities:** The two new checklist items (mock target verification, full shape assertions) could potentially be enforced via custom ESLint rules that check vitest mock targets against imports, but complexity likely exceeds value. Manual checklist enforcement is appropriate.

## Key Findings

1. **Local and post-push reviews found different issue classes.** Local review excelled at production code (triggers, queries, JSDoc, sort logic). Post-push review excelled at test code quality (mock targets, assertion shapes, fixture completeness, type mismatches). The adversarial review checklist was weak on test-specific quality checks.

2. **High fix-up ratio inflated by marker commits.** 80% raw ratio includes 2 marker commits. Substantive ratio is 40% (2 meaningful fix commits). Still above the 0% target but more reasonable for a 28-file cross-cutting feature.

3. **Two-round CodeRabbit pattern holds for large PRs.** This matches #131 (also 2 rounds). For PRs touching 20+ files across multiple layers, budget for 2 CodeRabbit rounds.

4. **Critical-severity finding was a test bug, not a production bug.** The most severe finding (wrong mock target) would have caused a confusing test failure, not a production bug. This is a lower-impact finding than it appears at first glance.

## Knowledge Updates

1. **process-patterns.md:** Added entry on 80% fix-up ratio with local vs. post-push issue class divergence. Added entries on test mock target gap and local-vs-post-push review complementarity. Added entry on two-round CodeRabbit norm for large PRs.
2. **testing-patterns.md:** Added mock target verification pattern. Added full object shape assertion pattern.
3. **adversarial-review.md:** Added test mock target verification (Tier 3). Added full object shape assertions (Tier 3). Updated test-only category mapping to include new items.

## Recommendations

1. **Strengthen test-specific adversarial review items.** The test-only category now has 5 items (UTC suffix, env isolation, error branch coverage, mock target verification, shape assertions). Consider promoting "test mock target verification" to Tier 1 (recurring blindspot) if it recurs.
2. **Consider separating marker commits from substantive fix commits.** Marker updates inflating fix-up ratio by 2x reduces the signal. Either: (a) squash marker updates into the preceding fix commit, or (b) exclude marker commits from ratio calculation.
3. **Budget 30+ minutes for CodeRabbit on large PRs.** The 2-round pattern is now confirmed across 3 large PRs (#131, #148, #159). Plan for this rather than being surprised.
