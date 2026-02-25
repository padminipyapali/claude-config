# Post-Mortem: second-brain PR #250 — Fix deadlock in curator acceptSuggestion

**Branch:** fix/curator-deadlock -> main
**Author:** padminipyapali (co-authored Claude Opus 4.6)
**Duration:** 0.48 hours (29 minutes)
**Size:** +37 -44 across 2 files, 1 commit
**Merged:** 2026-02-25T21:04:06Z

## Summary

Deadlock fix: `markAccepted`/`markDismissed` were using `pool.query()` (a different connection) while a `SELECT ... FOR UPDATE` lock was held on the transaction client from `pool.connect()`. Fix: thread the transaction `PoolClient` through all status update methods so they execute on the same connection that holds the row lock.

## Local Review (pre-push)

- **CodeRabbit findings:** not tracked (local review loop skipped)
- **Adversarial review findings:** not tracked (local review loop skipped)
- **Shift-left rate:** n/a

## Step Compliance

- **Steps run:** 2 (implement), 5 (push+PR) — 2 of 8
- **Steps skipped:** 1 (plan: trivial fix), 3 (Playwright: backend-only), 4a-4e (stated "under 50 LOC diff")
- **Compliance rate:** 25%
- **Skip assessment:** neutral
- **Note:** The stated skip reason for 4a-4e was "under 50 LOC diff," but actual diff is 81 LOC (+37/-44). The net change is -7 lines and the fix is mechanical (parameter threading), so the skip was pragmatically reasonable. However, it technically violates the >=50 LOC mandatory review threshold.

## Review Friction (post-push)

- **Review rounds:** 1 (CodeRabbit COMMENTED + APPROVED, no CHANGES_REQUESTED)
- **Comments:** 0 inline, 2 general (both bots: Vercel + CodeRabbit)
- **Substantive findings:** 1 CodeRabbit nitpick (outside diff range) suggesting explicit assertions that `UPDATE curator_suggestions` goes through `mockClientQuery` not `mockPoolQuery`
- **Categories:** { testing: 1 (nitpick level) }
- **Timeline:** created -> first review: 0.06h (4 min) | first review -> merge: 0.42h (25 min) | total: 0.48h

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (no substantive issues to catch — the 1 nitpick was enhancement-level)
- **Covered but missed:** n/a (review loop was skipped)
- **Not covered (new categories):** none
- **Fix commits:** 0 of 1 total (0% fix-up ratio)

The CodeRabbit suggestion about explicit deadlock-regression assertions is a testing best practice but was flagged as "Nitpick | Trivial" by CodeRabbit itself. It's an enhancement, not a bug.

## Planning Quality

- **Description:** complete (Summary, Test Plan, Local Review sections all present)
- **Scope:** clean — focused single-concern fix, no scope creep
- **Branch lifetime:** <1 hour
- **Planning checklist:** Plan step skipped (trivial fix justification). Reasonable for a focused mechanical fix.

## Code Quality Signals

- **Recurring issues:** none
- **Fix-up ratio:** 0% (single commit, no fix-ups)
- **New unrecorded patterns:** Transaction client affinity pattern already captured in adversarial-review.md (Tier 4) with source reference to this PR

## Process Efficiency

- **Automation opportunities:** none — this was a clean, fast PR
- **Iteration:** efficient (1 round, bot-approved)
- **CI status:** all passed (CodeRabbit SUCCESS, Vercel SUCCESS)

## Knowledge Updates

1. **adversarial-review.md** — "Transaction client affinity" checklist item already added to Tier 4 (db-sql category) with source reference to this PR. This captures the pattern: when a method acquires `pool.connect()` + `BEGIN` + `SELECT ... FOR UPDATE`, all subsequent queries on locked rows must use the same client.

2. **process-patterns.md** — No new process patterns. The PR demonstrates the ideal bug-fix flow: focused, single-commit, minimal scope, fast merge.

## Recommendations

1. **LOC threshold accuracy.** The skip reason stated "under 50 LOC diff" but the actual diff was 81 LOC. For future PRs, compute the actual diff size before deciding to skip the review loop. The 50 LOC threshold is in CLAUDE.md as a mandatory gate.

2. **Consider the CodeRabbit suggestion.** Adding explicit assertions that `UPDATE curator_suggestions` routes through the transaction client (not the pool) would serve as a regression test for this exact deadlock. It's not urgent but would strengthen the test suite.

3. **This is a model bug-fix PR.** Single commit, focused fix, good description, fast turnaround. The only process gap is the LOC threshold miscount for the review loop skip decision.
