# POST-MORTEM: second-brain PR #750 — feat(tags): one-time idempotent backfill to canonicalize existing tag rows

Branch: feat/tag-canonicalize-backfill → main | Author: padminipyapali | created→merged ~44s
Size: +842 -0 across 3 files, 1 commit (squash; final HEAD 581c64f)
Closes #748. Follow-up to #746/#747 (write-time canonicalization).

The 3 files: `canonicalize-tags-backfill.ts` (dry-run-by-default, `--apply` to mutate),
`026-tag-canonicalize-backfill.sql` (documented companion + approximate read-only impact query),
`canonicalize-tags-backfill.test.ts` (18 tests).

## LOCAL REVIEW (pre-push)
- CodeRabbit: not tracked (separate 4b skipped — covered by the 3-lens review + adversarial gate on a self-contained script).
- Adversarial: 2 findings, 2 fixed.
- 3-lens perspective-diverse code review (data-loss / idempotency-concurrency / SQL-edge-case): SHIP-READY, 0 must-fix.
- Build/lint/test: `npm run lint` clean; `tsc` clean; 2300 passed / 48 skipped (incl. 18 new).
- Shift-left: 100% of issues caught locally (2 adversarial-gate findings, 0 GitHub-review comments, 0 post-merge fixes).

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4c, 4d, 5 (7/9)
- Steps skipped: 4a (/simplify), 4b (CodeRabbit) — reason: covered by the 3-lens review (substitutes for the internal critic) + strict adversarial gate on a self-contained script.
- Compliance rate: 77.8%
- Skip assessment: **good** — no post-merge issues; the kept gates (3, 4c, 4d) were the load-bearing ones and 4c caught 2 real defects.

## STEP TIMING
| Step | Notes |
|---|---|
| 1 Plan | Earlier planning workflow → 2-PR split + this backfill spec |
| 2 Implement | Single pass (script + migration doc + 18 tests) |
| 3 Gates | lint / tsc / 2300 tests — green |
| 4 Review | 3-lens perspective-diverse review (SHIP-READY) → adversarial gate (caught NUL + trim; 2 fix cycles) → marker |
| 5 Apply | dry-run reviewed → `--apply` on prod (5 renames) → idempotency verified |
| 6 PR | this PR |

Per-step durations: null (notes-only table, no minutes). Bottleneck: the adversarial gate (2 fix cycles).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED; self-merged ~44s after creation).
- Comments: 0 inline, 0 human general (1 Vercel bot comment excluded).
- Categories: all 0.
- Timeline: created → merged ≈ 44 seconds. No GitHub review (local-review-is-the-gate flow; squash of locally-reviewed work).
- Self-merge check: mergedBy == author, no reviews → "no peer review" by GitHub, but pre-push gate was multi-layer (3-lens review + adversarial gate).

## ADVERSARIAL REVIEW EFFECTIVENESS
- adversarialCatchRate = **1.0** = caught-pre-merge / (caught-pre-merge + escaped-post-merge) = 2 / (2 + 0).
  - Caught pre-merge (2, both REAL):
    1. **NUL byte (U+0000) as the grouping-map delimiter** → git classified the `.ts` as BINARY, making the PR diff unreviewable. It had passed lint, `tsc`, 2300 tests, AND the 3-lens code review; only git's binary classification surfaced it. Fixed → single space (provably absent from UUIDs and canonical forms). This is the exact case that motivated **Tier-0 check 0.29** (already in adversarial-review.md:333, sourced to #748).
    2. **Non-`.trim()` env guard** (Tier-0 0.9), a pre-existing defect exposed once the NUL fix turned the file back into text. Fixed → `if (!databaseUrl?.trim())` (mirrors export-data.ts).
  - Escaped post-merge: 0 (latest merged PR; no follow-up fix PRs; no later PRs touch these files).
- The 3-lens perspective-diverse review returned SHIP-READY (0 must-fix) but **MISSED the NUL** — a vivid case where the adversarial gate caught what lint, tsc, 2300 tests, AND a 3-lens code review all missed.
- Pre-merge iteration count: 2 (gate failed twice before HEAD 581c64f passed).

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (0 post-merge fix commits — ideal).
- Pre-merge catch rate by step: 4a 0 | 4b 0 | 4c (adversarial) **2** | 4d 0 | post-push 0.
  (Both adversarial fixes were amended into the single squashed commit; they do not appear as separate fix commits in the merged history.)
- Pre-merge iteration count: 2 (gate-fail → fix → gate-fail → fix → pass). Normal for a destructive script; both iterations caught real defects.
- Fix-up taxonomy: { defensive-coding: 1 (trim guard), infrastructure: 1 (NUL/binary-source reviewability defect) }. The NUL fix is classed infrastructure (a diff/tooling-classification defect, not code-behavior quality) so it doesn't inflate the quality ratio.
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY
- Description: **complete** — What & why, How it works, Safety, Testing, Local Review, Step Timing; explicit "already applied to production" table.
- Scope: clean (single concept: the one-time backfill; the larger 3-part plan was already split in #747).
- Branch lifetime: ~minutes (single session).
- Planning checklist: entry points covered (singleton rename / collision merge / empty-canonical skip / idempotent re-run / cross-user isolation). No separate Performance & Cost section, but the destructive blast radius and safety analysis substitute appropriately for a one-time data-only migration.

## CODE QUALITY SIGNALS
- Recurring issues: none in this PR. The merge-collapse mechanics were already distilled into database-patterns.md:15 (rename-survivor-last, sourced to #748).
- New unrecorded patterns: the **process-ordering** lesson (apply-after-gate) was not previously a recorded principle — captured this round (see KNOWLEDGE UPDATES).

## PROCESS EFFICIENCY
- Automation opportunities: the NUL/binary-source defect is now grep-automatable via Tier-0 0.29 (already added). No further automation gap.
- Iteration: efficient post-push (0 rounds); 2 pre-merge gate cycles, each catching a real defect.
- CI status: Vercel Preview SUCCESS; server suite green (2300/48).

## PROCESS FLAGS (raised by the gate)
1. **Destructive backfill was APPLIED to prod before the adversarial gate passed and before merge.** Ordering was: dry-run reviewed → user-approved → `--apply` (5 renames) → idempotency verified → THEN adversarial gate (failed twice) → PR. Outcome was clean (the gate's findings were a reviewability defect + a guard, not data loss), but an un-gated destructive script touched production. Captured as a process principle (strategic-decisions.md, Product Lifecycle & Process): for destructive prod migrations, complete the full review gate before applying — gate-pass → merge → apply — even with explicit user authorization to apply; authorization is permission for the action, not a waiver of the review ordering.
2. **NUL byte defeating lint/tsc/tests/3-lens-review** is the gap now closed by Tier-0 check 0.29 (already in adversarial-review.md:333). Referenced, not re-added.

## KNOWLEDGE UPDATES
- **strategic-decisions.md** (Product Lifecycle & Process): NEW principle — "For a DESTRUCTIVE production migration/backfill, complete the FULL review gate (and ideally land the PR) BEFORE applying it to prod — gate-pass → merge → apply, even with explicit user authorization." Sourced to second-brain #750. This is the *when* that pairs with database-patterns.md's *how* (rename-survivor-last/dry-run-by-default).
- **adversarial-review.md**: NO change — Tier-0 0.29 (NUL/binary-source) already present (line 333, sourced to #748).
- **database-patterns.md**: NO change — merge-collapse/rename-survivor-last already present (line 15, sourced to #748).
- **post-mortem-metrics.json**: appended entry #403 for PR #750 (adversarialCatchRate 1.0).
- **dashboard.html**: regenerated with the 403-PR dataset.

## RECOMMENDATIONS
1. **Adopt apply-after-gate for destructive prod migrations.** The single most valuable lesson here. The gate is precisely the layer that caught what lint/tsc/2300-tests/3-lens-review all missed; running the irreversible `--apply` before that gate forfeits its protection for the one operation that least tolerates it. The new strategic-decisions.md principle is the artifact; the lighter-weight enforcement is a checklist line in the destructive-migration runbook: "adversarial gate PASS (marker for current HEAD) is a precondition for `--apply`, not just for `git push`."
2. **Keep the 3-lens review, but do not treat SHIP-READY as gate-equivalent on destructive work.** The 3-lens review added value (perspective-diverse correctness coverage) yet missed the NUL; SHIP-READY from a code review is not a substitute for the adversarial gate's mechanical greps. Both layers earned their place; neither replaces the other.
3. **No new automation needed.** Tier-0 0.29 already grep-catches the NUL/binary-source class going forward.
