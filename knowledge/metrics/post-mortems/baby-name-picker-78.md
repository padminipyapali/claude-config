# POST-MORTEM: baby-name-picker PR #78 — Show name pronunciation on the compare card

Branch: `feat/compare-card-pronunciation` → `main` | Author: padminipyapali | created 2026-05-28T19:31:44Z, merged 20:02:54Z (~31 min)
Size: +979 -0 across 5 files, 1 commit (squash-merged, self-merged)

## LOCAL REVIEW (pre-push)
- CodeRabbit: 0 findings (CLI run after scoping base to `origin/main`).
- Adversarial: Tier 0 run, 0 findings (pure render change; no SQL/async/fire-and-forget).
- 4a `/simplify` folded into the fresh-context critic.
- Critic verdict: SHIP (NITs only); one NIT (empty-string test case) folded pre-merge.
- Shift-left: n/a — no issues escaped to GitHub.

## STEP COMPLIANCE
- Steps run: 1, 2a, 2b, 3, 4a, 4b, 4c, 5 (8/9 = 88.9%).
- Steps skipped: 4d (CI) — no CI checks configured in repo.
- Skip assessment: neutral (no CI configured; no post-merge issues attributable to the skip).

## REVIEW FRICTION (post-push)
- Review rounds: 1 (0 CHANGES_REQUESTED). reviewDecision empty.
- Comments: 0 inline, 0 general. statusCheckRollup empty (no CI).
- Self-merge: mergedBy == author, no reviews → no peer review.

## ADVERSARIAL REVIEW EFFECTIVENESS
- adversarialCatchRate: **unmeasured**. Derivation: zero post-push review issues and zero fix commits → no denominator of escaped issues against which to compute a catch rate. Marked `"unmeasured"` per the integrity rule (never hardcode a baseline).
- Tier 0 ran clean; the change is a guarded render addition with no async/SQL surface.

## FIX-UP METRICS
- Post-merge fix rate: 0.0 (no follow-up fix commits/PRs touch NameCard).
- Pre-merge catch-rate by step: all 0 (the NIT + fixture fixes were folded into the single commit, not separate fix commits).
- Pre-merge iteration count: 1 (healthy).
- Fix-up taxonomy: all 0 (folded).
- Legacy fix-up ratio: 0.0 (0 fix / 1 total commit).

## PLANNING QUALITY
- Description: complete (Summary, Design, Local Review, Test plan, Out-of-scope).
- Scope: clean, single concern. Branch lifetime well under 48h.
- Planning checklist: entry points (present/null/empty/whitespace) enumerated; family-unit layout invariant called out.

## CODE QUALITY SIGNALS — NOTABLE FINDING
- **Stale-branch integration break / red main.** This PR also carried a one-line test-only fix (`familyJson: null`) to `gameStore.perGender.test.ts`, whose `makeName` fixture was missing the now-required `Name.familyJson` field — `tsc` and that jest suite were RED on `origin/main` between the #73/family-tree work. The #73 post-mortem did not catch that main had gone red. The pronunciation work inherited a broken gate and fixed it inline so the mandated check passed.
- New unrecorded patterns: none (the stale-branch class is already in process-patterns.md line 28; strengthened with this confirmation).

## PROCESS EFFICIENCY
- Automation opportunity: a post-merge `tsc`/jest gate on `main` (or required CI checks) would have surfaced the red main immediately rather than at the next feature's rebase.
- Iteration: efficient (1 round, ~31 min).
- CI status: none configured.

## KNOWLEDGE UPDATES
- Strengthened process-patterns.md "rebase a stale feature branch … BEFORE running review gates" entry with the #78 confirmation that main went red undetected and the next PR absorbed the fix.

## RECOMMENDATIONS
1. Configure required CI checks (`tsc`/jest) so a red main is caught at merge, not at the next feature's rebase.
2. Continue running 4b CodeRabbit on every PR regardless of size (this PR did — good).
