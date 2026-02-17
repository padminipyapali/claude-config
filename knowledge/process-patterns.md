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
- **New gap: String truncation arithmetic.** When slicing + appending to fit a max length, verify `slice_length + suffix_length <= limit`. Added to knowledge but not yet in adversarial checklist. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->
- **New gap: User-facing text compound wrapping.** When a helper function adds decoration (e.g., parentheses) and callers add more, the result compounds (e.g., `((all day))`). Review all format helper return values against their call sites. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->

## Automation Opportunities

- **UTC suffix enforcement via lint rule.** A custom ESLint rule or grep check for `new Date("...:00")` without trailing `Z` would catch the most common timezone bug class automatically. Multiple PRs have hit this. **Decision:** Deferred CI-level lint rules. Instead, Tier 0 automated grep checks in the adversarial review checklist serve the same purpose without per-project setup cost. If patterns are still missed after Tier 0 is live, escalate to GitHub Actions workflows. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->

## Iteration Velocity

- **75% fix-up ratio on first tracked PR.** 3 of 4 commits were review fixes. All mechanical, all fast — but the ratio indicates the adversarial review is not catching enough pre-push. Target: <50% fix-up ratio. <!-- Source: post-mortem, second-brain #131, 2026-02-16 -->

---
*Sources: post-mortem analysis across all projects*
