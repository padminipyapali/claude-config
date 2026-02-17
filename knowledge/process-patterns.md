# Process Patterns

Cross-project learnings about the development process: review efficiency,
planning discipline, iteration velocity, and automation opportunities.

## Review Efficiency

- **Bot-only review catches real bugs but inflates round count.** CodeRabbit found 4 correctness issues on first review of PR #131, producing 2 review rounds and 75% fix-up ratio. All fixes were mechanical (<20 min total), but the commit noise adds up. Expect 2+ rounds as baseline when only bot reviews. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **Self-merge with bot-only review misses architectural feedback.** Bot reviewers catch syntax and correctness but can't assess "is this the right abstraction?" or "does this belong in this file?" No human review means architecture debt accumulates silently. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->

## Planning Discipline

- **Thorough planning reduces implementation rework.** PR #131 had a detailed plan (entry points, DRY analysis, adversarial review section, performance/cost) and zero redesign commits. All fix commits were review-driven, not planning gaps. The plan paid off. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->

## Adversarial Review Gaps

- **Checklist items present but not mechanically executed.** "UTC suffix in test Date strings" was literally in Tier 3 of the adversarial review checklist, yet test dates without Z suffix shipped. The bottleneck is execution discipline, not checklist coverage. Fix: run grep patterns, not just read items. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **Unmount guard pattern known but not applied to new code.** PR #140's adversarial review reported 0 findings, but CodeRabbit caught a missing `isMountedRef` unmount guard — a pattern already documented in `react-patterns.md` and used by 3 sibling hooks in the same file. The adversarial review needs to cross-reference new async hooks against sibling patterns in the same file. <!-- Source: post-mortem, second-brain #140, 2026-02-17 -->
- **Copy-and-adapt defeats adversarial review discipline.** PR #143 adapted the inline-edit pattern from PR #142 to the TODO panel. The adversarial review claimed to find and fix 3 issues (Escape propagation, keyboard a11y, state cleanup), but all 3 shipped incomplete — CodeRabbit caught `role="button"` on span, Escape only on textarea, and missing save-guard. The checklist items (Tier 3: "Semantic elements", "Escape in edit-within-panel") have precise wording that would have prevented these. Root cause: "I already fixed this" cognitive shortcut when adapting patterns. Fix: re-run the checklist against the NEW instance, not assume coverage from the prior fix. <!-- Source: post-mortem, second-brain #143, 2026-02-17 -->
- **New gap: String truncation arithmetic.** When slicing + appending to fit a max length, verify `slice_length + suffix_length <= limit`. Added to knowledge but not yet in adversarial checklist. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **New gap: User-facing text compound wrapping.** When a helper function adds decoration (e.g., parentheses) and callers add more, the result compounds (e.g., `((all day))`). Review all format helper return values against their call sites. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **New gap: Test value swap vs. behavioral assertion.** When updating tests for a behavioral change, the adversarial review should verify whether the test asserts the OLD behavior with a new value or the NEW behavior entirely. PR #145 changed `"Interesting thought!"` to `"Thought saved."` in `toHaveBeenCalledWith` but did not change the assertion to `not.toHaveBeenCalled`, which was the actual behavioral change specified in the requirement. Value swaps are mechanical; behavioral verification requires reading the spec. <!-- Source: post-mortem, second-brain #145, 2026-02-17 -->
- **New gap: Test env variable isolation.** When tests mutate `process.env.*` (set in `beforeEach`, deleted in a test), the adversarial review should verify cleanup in `afterEach`. Without restore, env mutations leak to subsequent test files. The test-only category in the checklist lacks test isolation checks. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->
- **New gap: Missing error branch test coverage.** When a route has distinct error paths (timeout/AbortError -> 504, non-404 error -> 502), tests should cover each branch. The adversarial review should verify that all catch/error branches in new route handlers have corresponding test cases. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->

## Process Compliance

- **Small changes are not exempt from the development flow.** PR #153 (6 LOC, 1 file) skipped steps 3 (lint + test), 4 (code review loop), and went straight to push. The CLAUDE.md development flow applies regardless of change size — the steps exist for consistency, not just for catching bugs in large PRs. The agent rationalized skipping as "minimal change" but the process doesn't have a size-based exemption. <!-- Source: post-mortem, second-brain #153, 2026-02-17 -->

## Automation Opportunities

- **UTC suffix enforcement via lint rule.** A custom ESLint rule or grep check for `new Date("...:00")` without trailing `Z` would catch the most common timezone bug class automatically. Multiple PRs have hit this. **Decision:** Deferred CI-level lint rules. Instead, Tier 0 automated grep checks in the adversarial review checklist serve the same purpose without per-project setup cost. If patterns are still missed after Tier 0 is live, escalate to GitHub Actions workflows. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **Run Biome lint before push to catch a11y issues.** PR #143 shipped a `span` with `role="button"` that Biome's `noStaticElementInteractions` rule would have flagged. Running `npm run lint` as part of the pre-push workflow would have prevented at least 1 of 3 fix rounds. The lint output was either not generated or not reviewed before push. <!-- Source: post-mortem, second-brain #143, 2026-02-17 -->

## Iteration Velocity

- **0% fix-up ratio with full local review loop.** PR #142 (650 LOC, 18 files) achieved zero post-push findings and zero fix commits by running the complete code review loop (simplifier → CodeRabbit → adversarial → CI) before push. CodeRabbit found 4 real issues locally; all were fixed before the PR was created. This is the target outcome — shift all quality catches to pre-push. <!-- Source: post-mortem, second-brain #142, 2026-02-17 -->
- **75% fix-up ratio on first tracked PR.** 3 of 4 commits were review fixes. All mechanical, all fast — but the ratio indicates the adversarial review is not catching enough pre-push. Target: <50% fix-up ratio. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **0% fix-up ratio across PRs #135-#137.** Three consecutive clean PRs with no review-driven fix commits. However, PR #136 had a legitimate correctness finding that was left unaddressed (merged 1 min after CHANGES_REQUESTED). Zero fix-up ratio can mask ignored findings. <!-- Source: post-mortem, second-brain #135-137, 2026-02-17 -->
- **50% fix-up ratio on small focused PR.** PR #140 had 2 commits, 1 feature + 1 review fix. On small PRs (29 LOC), one review finding immediately produces a high ratio. Context matters more than the absolute number for small changesets. <!-- Source: post-mortem, second-brain #140, 2026-02-17 -->
- **75% fix-up ratio on pattern-adaptation PR despite local review.** PR #143 (242 LOC, 3 files) had 3 of 4 commits as review fixes, matching the worst performance in the series (PR #131). The PR adapted an inline-edit pattern from one component to another and claimed local adversarial review, but fixes were incomplete. Copy-and-adapt work is higher-risk for review quality than greenfield implementation. <!-- Source: post-mortem, second-brain #143, 2026-02-17 -->
- **0% fix-up ratio with unresolved review finding (false clean).** PR #145 (44 LOC, 3 files) had 1 commit and 0 fix commits, but merged with an outstanding CHANGES_REQUESTED. CodeRabbit found a spec-implementation mismatch (test asserts behavior contradicting the stated requirement). The 0% ratio is technically accurate but masks the unresolved finding. Same pattern as PR #136. When evaluating fix-up ratio, check whether CHANGES_REQUESTED reviews were addressed or ignored. <!-- Source: post-mortem, second-brain #145, 2026-02-17 -->
- **50% fix-up ratio with partial review addressing.** PR #148 (601 LOC, 23 files) had 2 commits, 1 feature + 1 fix. Addressed 2 of 4 actionable post-push findings (env leakage, TODO tracking), left 2 unaddressed (restoreAllMocks in afterEach, timeout test coverage). Merged with 2nd CHANGES_REQUESTED outstanding. Local review caught 6 issues pre-push (60% shift-left rate), but test isolation gaps still escaped both local and adversarial reviews. <!-- Source: post-mortem, second-brain #148, 2026-02-17 -->

## Documentation Review Noise

- **Markdownlint findings inflate review rounds on docs PRs.** PR #141 had 2 review rounds, both on a README.md file: missing blank lines around headings/tables and missing fence language. These are mechanical lint issues, not code quality problems. When a PR includes docs, expect 1 extra CodeRabbit round for markdown lint. Mitigation: run markdownlint locally before push, or accept the noise as baseline. <!-- Source: post-mortem, second-brain #141, 2026-02-17 -->

## Review Discipline

- **Merging immediately after CHANGES_REQUESTED bypasses review purpose.** PR #136 was merged 1 minute after CodeRabbit flagged a race condition (stale closure in background refresh). The finding was legitimate and could cause stale data to flash on rapid tab switching. Even for bot reviews, acknowledge findings explicitly before merging: dismiss with a reason, or fix. **Repeat occurrences:** PR #145 merged 3 minutes after CodeRabbit flagged a test-spec behavioral mismatch. PR #148 merged ~2 minutes after CodeRabbit's 2nd review (CHANGES_REQUESTED) with 2 unaddressed findings (restoreAllMocks in afterEach, missing timeout test coverage). This is now a 3-PR pattern. <!-- Source: post-mortem, second-brain #136, #145, #148, 2026-02-17 -->
- **CodeRabbit rate limits cause review gaps.** Three PRs submitted within minutes (#135, #136, #137) hit the hourly review limit. PR #137 received no code review at all before merge. Mitigation: space out PR submissions by 10+ minutes, or wait for rate limit expiry (~8 min) before merging. <!-- Source: post-mortem, second-brain #136-137, 2026-02-17 -->
- **CodeRabbit monorepo false positives are recurring noise.** CodeRabbit's sandbox runs `npm test` without building shared packages first, producing false test failures on every monorepo PR. This adds review rounds without value. Consider documenting as known limitation or configuring CodeRabbit to skip test execution. <!-- Source: post-mortem, second-brain #135, 2026-02-17 -->

---
*Sources: post-mortem analysis across all projects*
