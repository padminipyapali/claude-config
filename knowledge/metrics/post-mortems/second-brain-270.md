# Post-Mortem: second-brain PR #270 — Guard optimistic reverts against stale failures

**Branch:** fix/optimistic-revert-guard -> main
**Author:** padminipyapali | **Merged by:** padminipyapali
**Created:** 2026-02-26T12:49:37Z | **Merged:** 2026-02-26T13:50:05Z | **Duration:** 1.01 hours
**Size:** +10 -4 across 1 file, 1 commit

## Summary

This PR extends the stale-revert guard pattern introduced in PR #269 (Ideas panel) to three additional optimistic update sites in `packages/web/src/hooks.ts`:
- `useFeed.setTodoStatus` — guards `e.todoStatus === newStatus` before revert
- `useFeed.updateDueDate` — guards `e.dueDate === dueDate` before revert
- `useTodos.updateDueDate` — guards `e.dueDate === dueDate` before revert

This prevents a slow-failing earlier request from reverting over a later successful update when a user rapidly triggers the same action.

## Local Review (pre-push)

- **CodeRabbit findings:** not tracked (null) — steps skipped
- **Adversarial findings:** not tracked (null) — steps skipped
- **Shift-left rate:** n/a — local review loop not run

Steps skipped: 1 (plan), 3 (test), 4a-4d (full review loop). Justification: under 50 LOC mechanical fix, pattern already established in #269. CI (build, lint, 76 web tests) was run and passed.

## Step Compliance

- **Steps run:** 2 (implement), 5 (push+PR) — 2 of 8
- **Steps skipped:** 1 (plan), 3 (test), 4a (simplification), 4b (internal review), 4c (CodeRabbit), 4d (adversarial) — 6 of 8
- **Compliance rate:** 25%
- **Skip assessment:** neutral

The skip is justified per process rules: diff is 14 LOC (well under the 50 LOC threshold), and the pattern is mechanical replication of an established fix from PR #269. The one post-push finding (see below) was a nitpick outside the diff range.

## Review Friction (post-push)

- **Review rounds:** 1 (0 CHANGES_REQUESTED, direct APPROVED by CodeRabbit)
- **Comments:** 0 substantive (2 bot comments: Vercel deployment, CodeRabbit walkthrough)
- **Inline comments:** 0
- **Categories:** { style: 0, correctness: 0, architecture: 0, security: 0, performance: 0, testing: 0, documentation: 0, other: 0 }
- **Timeline:** created -> first review: 0.04h (2.2 min) | first review -> merge: 0.97h | total: 1.01h

Note: CodeRabbit posted 1 outside-diff-range nitpick in its review body (not an inline comment): "Consider applying the same stale-revert guard to `handleToggleStar` for consistency." This was marked as Trivial/Nitpick by CodeRabbit itself and was not a blocking finding.

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 100% (1/1 findings covered by checklist)
- **Covered but missed:** Tier 1.5 (Optimistic UI Revert Safety item 3: staleness guard) + Tier 4 (pattern siblings) — the `handleToggleStar` consistency suggestion maps directly to these checklist items
- **Not covered (new categories):** none
- **Fix commits:** 0 of 1 total (0.0% fix-up ratio)

The adversarial review was deliberately skipped (<50 LOC). The one finding it would have caught is a consistency nitpick outside the diff range, not a correctness bug.

## Planning Quality

- **Description:** complete (Summary, Test Plan, Local Review sections present)
- **Scope:** clean (single concern, 14 LOC, 1 file)
- **Branch lifetime:** 1.01 hours
- **Planning checklist:** skipped (mechanical fix, no plan needed for pattern replication)

## Code Quality Signals

- **Recurring issues:** none
- **Fix-up ratio:** 0.0% (0 fix commits of 1 total)
- **New unrecorded patterns:** none — the stale-revert guard pattern was already captured in adversarial-review.md Tier 1.5 item 3 from PR #269

## Process Efficiency

- **Automation opportunities:** The CodeRabbit nitpick about `handleToggleStar` could be caught by a grep-based pattern siblings check. However, since this was outside the diff range and marked as trivial, it is a follow-up optimization, not a missed catch.
- **Iteration:** efficient (1 round, direct approval, 0% fix-up ratio)
- **CI status:** all passed (Vercel deployment SUCCESS, CodeRabbit SUCCESS, Auto-Fix PR Reviews SKIPPED)

## Observations

1. **Good pattern for mechanical follow-up PRs.** This PR is the ideal shape for a "pattern sibling" fix: small, focused, replicating an established pattern from a preceding PR (#269). The skip of steps 1/3/4a-4d is justified and saved significant process overhead for a 14 LOC change.

2. **CodeRabbit's nitpick reveals a remaining instance.** The `handleToggleStar` function in the same file still lacks the stale-revert guard. This is a valid consistency improvement that should be addressed in a follow-up. The fact that CodeRabbit caught it validates the "pattern siblings" checklist item.

3. **Self-merge with bot-only review is acceptable here.** For a 14 LOC mechanical fix replicating an established pattern, the risk of self-merge is minimal. The pattern was already reviewed by humans in a prior PR.

## Knowledge Updates

No new patterns to capture. The stale-revert guard pattern is already documented in:
- `~/.claude/knowledge/adversarial-review.md` Tier 1.5 item 3 (added from PR #269)
- Process patterns already cover the "mechanical follow-up PR" pattern

## Recommendations

1. **Address the `handleToggleStar` consistency gap.** CodeRabbit identified that `handleToggleStar` (and potentially `updateEntry`) lack the same stale-revert guard. Consider a small follow-up PR to complete the pattern across all optimistic update sites in hooks.ts.
