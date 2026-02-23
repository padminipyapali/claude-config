# Post-Mortem: second-brain PR #211

**Title:** Add research REST API routes (Issue #130, PR 4/8)
**Branch:** feat/research-telegram -> main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-02-23T12:51:59Z | **Merged:** 2026-02-23T16:02:48Z
**Size:** +876 -13 across 9 files, 6 commits (4 feature/fix + 1 merge + 1 misc)
**Duration:** 3.18 hours

## Local Review (pre-push)

- **Steps skipped:** 3-Playwright (backend-only, justified), 4c-CodeRabbit (rate-limited)
- **Internal review findings:** 0 issues in new route files (5 pre-existing in prior PR code)
- **Code simplification findings:** 2 improvements applied (parseUuidParam helper, VALID_FEEDBACK_VALUES constant)
- **Adversarial review findings:** 0 issues in new files, 1 low-severity pre-existing observation
- **CodeRabbit local:** skipped (rate-limited)
- **CI status:** build + lint + 899 tests all passed

**Local issues caught:** 2 (code simplification) + 1 (adversarial pre-existing) = 3 actionable
**Shift-left rate:** 3 local / (3 local + 5 post-push) = 37.5%

## Post-Push Review (CodeRabbit)

### Round 1: CHANGES_REQUESTED (5 inline comments)

1. **escHtml missing quote escaping** (research-reply.ts) - Trivial/Nitpick
   - Category: correctness
   - Checklist coverage: Partially covered (Tier 2 "Escape user content") but specific to HTML entity completeness
   - Status: Fixed in commit 29a57cd

2. **markResearchInitiated called before startResearch** (message-processor.ts) - Major
   - Category: correctness
   - Checklist coverage: Tier 4 "At-most-once dedup markers BEFORE the action" is inverse; side-effect ordering around fallible operations is conceptually covered but not explicit for "mark AFTER success" pattern
   - Status: Fixed in commit 29a57cd

3. **Test env values deleted instead of restored** (research.test.ts) - Minor
   - Category: testing
   - Checklist coverage: **Explicitly covered** by Tier 3 "Test env variable isolation" ("verify cleanup in afterEach that captures and restores the original value")
   - Status: Fixed in commit 29a57cd

4. **UUID v4 comment doesn't match regex** (research.ts) - Minor
   - Category: documentation
   - Checklist coverage: **Covered** by Tier 4 "Documentation sync" ("JSDoc matches code")
   - Status: Fixed in commit 29a57cd

5. **discardReason accepts any string, should validate against enum** (research.ts) - Minor
   - Category: correctness
   - Checklist coverage: **Covered** by Tier 2 "Input validation at boundaries"
   - Status: Fixed in commit 29a57cd

### Round 2: APPROVED

No new findings after fix commit. Clean approval.

## Merge Conflicts

5 files with 10 conflict blocks from concurrent main-branch merges. All resolved by keeping the PR's review fixes. No rework required.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 3 of 5 post-push findings are covered by existing adversarial checklist items (test env isolation, documentation sync, input validation). Catch potential = 60%.
- **Covered but missed:**
  - Tier 3 "Test env variable isolation" -> finding #3 (test env restore)
  - Tier 4 "Documentation sync" -> finding #4 (UUID comment mismatch)
  - Tier 2 "Input validation at boundaries" -> finding #5 (discardReason validation)
- **Not covered (new categories):**
  - HTML entity completeness in custom escape helpers (finding #1)
  - Side-effect ordering: "mark after success, not before attempt" for state flags around fallible operations (finding #2)

## Fix-Up Ratio

| Commit | Classification |
|--------|---------------|
| Add Telegram research integration | feature |
| Address PR review: clear inline keyboard | fix (prior PR's finding) |
| Update packages/server/src/channels/telegram.ts | feature (misc) |
| Add research REST API routes (Issue #130, PR 4/8) | feature |
| Address PR review: escape quotes, fix ordering, etc. | fix |
| Merge remote-tracking branch origin/main | merge |

Fix commits: 2 of 5 non-merge commits = **40% fix-up ratio**

Note: 1 fix commit ("clear inline keyboard") addresses findings from the prior PR (#209), not this PR's scope. If counting only this PR's review fixes, it's 1 fix out of 4 substantive commits = 25%.

## Planning Quality

- **Description:** Complete (summary, route table, test plan, local review section)
- **Scope:** Clean -- 8 endpoints with tests, no scope creep
- **Branch lifetime:** 3.18 hours
- **Redesign indicators:** None (no revert/undo/redesign commits)
- **Planning checklist:** Route table with status codes and purposes. Test plan covers auth, validation, error mapping. No performance/cost section (acceptable for CRUD routes).

## Step Compliance

- **Steps run:** 1, 2, 3, 4a, 4b, 4d, 5 (7 of 8)
- **Steps skipped:** 4c (CodeRabbit local -- rate limited), 3-Playwright (backend-only, justified)
- **Compliance rate:** 75% (6/8 trackable steps -- Playwright skip is justified, CodeRabbit skip was forced)
- **Skip assessment:** bad -- CodeRabbit rate limit caused 5 findings to escape to post-push. 3 of those 5 are covered by adversarial checklist items that also weren't caught. The CodeRabbit skip is not the root cause; the adversarial review missing its own checklist items is.

## Recommendations

1. **Adversarial review execution discipline (recurring).** 3 of 5 post-push findings map to existing checklist items. This is the 4th consecutive PR where the adversarial review has items on its checklist but doesn't catch them. The issue is mechanical execution, not coverage gaps. Consider: numbered verification with explicit pass/fail for each item.

2. **Add "side-effect ordering around fallible ops" to Tier 3.** The markResearchInitiated-before-startResearch pattern is a general correctness issue: state flags that assume success should be set AFTER the operation, not before. This is distinct from the Tier 4 "dedup markers BEFORE action" pattern (which is about idempotency, not optimistic state).

3. **HTML entity completeness for custom escape helpers.** When writing custom `escHtml`/`escapeHtml` functions, verify all 5 HTML entities are covered: `&`, `<`, `>`, `"`, `'`. A Tier 0 grep could flag custom escape functions with fewer than 5 replacements.

4. **Budget CodeRabbit rate limits into multi-PR workflows.** This is the 2nd PR in a series that hit CodeRabbit rate limits. When pushing multiple PRs within an hour, either space them 30+ minutes apart or run CodeRabbit locally before the rate limit window.

---
*Generated: 2026-02-23*
