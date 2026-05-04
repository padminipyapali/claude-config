# POST-MORTEM: remodel-hq PR #23

**Title:** Fix migration 018 collision (vote/favorite unique constraint)
**Branch:** fix/migration-018-collisions → main | Author: padminipyapali
**Created → Merged:** 2026-05-04T19:15:05Z → 2026-05-04T19:15:37Z (~32 seconds)
**Size:** +215 / -0 across 1 file, 1 commit (new migration `019_dedupe_inspo_images_v2.sql`)

## Local Review (pre-push)
- CodeRabbit: not tracked
- Adversarial: not tracked
- Shift-left rate: n/a
- 5th consecutive remodel-hq PR (#19–#23) without a `## Local Review` section.

## Step Compliance
- Not tracked (PR body has no `Steps skipped:` line).

## Step Timing
- Not tracked (no `## Step Timing` section).

## Review Friction (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED, no APPROVED, no reviews at all)
- Comments: 0 inline, 1 general (Vercel deploy bot — excluded from category counts)
- Categories: all zero
- Timeline: created → merged in 32 s. Self-merged by author with no peer review.

## Adversarial Review Effectiveness
- Pre-push catch potential: n/a (no review surface to compare against).
- Notable: this PR exists *because* PR #18 (the original migration 018) shipped a duplicate-key bug that adversarial review didn't catch. The bug class — "UPDATE that repoints rows into a unique constraint without first deduping the destination key space" — belongs in the DB checklist.

## Fix-up Metrics
- Post-merge fix rate: 0% so far (PR 23 is the latest).
- Pre-merge iteration count: 1.
- Fix-up taxonomy: this PR itself counts as `correctness` for the *prior* PR #18; from PR 23's own perspective, taxonomy is empty.
- Legacy fix-up ratio: 1.0 (1 fix commit / 1 total) — the entire PR is a fix.

## Planning Quality
- Description: complete (Summary + Migration to apply + Test plan)
- Scope: clean — single concern (one migration file)
- Branch lifetime: ~30 seconds (urgent prod-fix workflow)
- Test plan: tsc/test/build all checked; one item left intentionally unchecked (`Apply 019 to Supabase`) since that's a manual prod step.

## Code Quality Signals
- Migration is idempotent + transactional.
- `IF NOT EXISTS` guard on partial unique index creation.
- `NULLS FIRST` ordering on tiebreaker — matches the same defensive pattern noted in PR 22.
- The new migration's logic (delete-losers-first, then repoint-survivors) is the canonical fix for the original bug class.

## Process Efficiency
- CI: Vercel preview SUCCESS.
- Iteration: efficient (1 commit, 1 file).
- 32-second self-merge with zero review is a hot-fix pattern. Acceptable when reverting a prod outage; risky as a default.

## Knowledge Updates
- Added DB pattern to `database-patterns.md`: "Repoint-then-dedupe ordering bug." When merging duplicate rows that have unique constraints on `(parent_id, user_key)`, dedupe by destination key BEFORE repointing FKs onto the canonical parent — otherwise the UPDATE collides with the existing unique constraint. Source: post-mortem remodel-hq #23, 2026-05-04.

## Recommendations
1. **Adopt the `## Local Review` PR template section.** Five consecutive remodel-hq PRs now lack it — the data gap is now systemic and is the highest-leverage process fix.
2. **Hot-fix policy.** A 32-second self-merge is fine for prod incidents but should leave a marker in the PR body (e.g., `Hot-fix: bypassing local review because <reason>`). That makes future post-mortems able to distinguish "skipped review intentionally" from "forgot to track it."
3. **Add the repoint-then-dedupe rule to the DB checklist.** PR #18 (this PR's parent) would have been caught by it. This is the single concrete adversarial-review gap surfaced by the post-mortem.
