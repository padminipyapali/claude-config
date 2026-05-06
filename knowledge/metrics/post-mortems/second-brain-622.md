# POST-MORTEM: second-brain PR #622

**Title:** feat(web): conditional Active Projects strip — pill row + dormant link
**Branch:** feat/conditional-projects-strip → main
**Author:** padminipyapali | **Merged by:** padminipyapali (self-merge)
**Created:** 2026-05-06T23:24:36Z | **Merged:** 2026-05-06T23:36:44Z | **Duration:** 0.20h (~12 min)
**Size:** +451 / -543 across 12 files, 1 commit | Closes #621

## Local Review (pre-push)

- **/simplify (4a):** ran — implementer flagged a single optional `useMemo` in `App.tsx`, judged not worth dep-wiring cost. No findings worth fixing.
- **CodeRabbit CLI (4b):** **skipped** — reason: "local critic + per-package vitest + tsc clean is the gate; CodeRabbit CLI not required to merge."
- **Adversarial (4c):** **PASS** on all 16 checklist items. Body includes structured evidence: sibling sweep on `ApiProjectWithProgress` (3 fixtures + 1 optimistic decoration), single-source-of-truth on `isActiveToday`, timezone correctness (`Intl.DateTimeFormat("en-CA", { timeZone })`), cross-user SQL safety (`p.user_id = $1` + `e.user_id = p.user_id`), CSS deletion safety, a11y (`type="button"` + aria-labels), dormant-state create-project regression check.

Shift-left rate: n/a (no findings → no caught-locally count).

## Step Compliance

- **Steps run:** 1, 2a, 2b, 3, 4a, 4c, 4d, 5 (8/9)
- **Steps skipped:** 4b (CodeRabbit) — reason: "local critic + vitest + tsc clean is the gate"
- **Compliance rate:** 88.9% (8/9)
- **Skip assessment:** **neutral** — no post-push reviews occurred (self-merged in 12 min, no human/bot review). Cannot validate whether CodeRabbit would have surfaced an issue. Note: this is the second consecutive PR (after #614 which set the precedent) where 4b was deliberately skipped with the same justification, despite the global rule "If CodeRabbit CLI times out, retry once with 2-min backoff — don't skip." The local rationale is reasonable for low-risk UI changes, but the skip pattern is now recurring.

## Step Timing

Not tracked — the new `.github/PULL_REQUEST_TEMPLATE.md` does not include a `## Step Timing` section. Consistent with PR #618, #620, #614 since the template change.

## Review Friction (post-push)

- **Review rounds:** 0 (no APPROVED, no CHANGES_REQUESTED, no human reviews)
- **Comments:** 0 inline, 1 general (vercel preview bot — excluded as bot)
- **Categories:** all zeros
- **Timeline:** created → merged: 0.20h. No first-review checkpoint (none happened).
- **Self-merge check:** **flagged** — `mergedBy == author` and zero reviews. By the definition in this skill: "no peer review."

## Adversarial Review Effectiveness

- **Pre-push catch potential:** unmeasured — no post-push findings exist to compute the catch rate against. The body claims PASS on 16 items with concrete evidence per item, which is the correct artifact format.
- **Covered but missed:** none discoverable (no review surfaced any miss).
- **Not covered (new categories):** none discovered.
- **Iteration overhead:** 0 fix commits / 1 total commit.

## Fix-up Metrics

- **Post-merge fix rate:** 0.0 — PR #622 is the most recent merged PR; no follow-up fix PRs exist (yet).
- **Pre-merge catch rate by step:** all zeros — no fix commits anywhere on the branch. Single feature commit.
- **Pre-merge iteration count:** 1 (healthy).
- **Fix-up taxonomy:** all zeros.
- **Legacy fix-up ratio:** 0.0 (0 fix / 1 total).

## Planning Quality

- **Description:** **complete** — Summary, Test plan, Local Review, Performance & Cost Impact all populated per the new template. Includes concrete activity rule, mockup reference, API change note.
- **Scope:** **clean** — branch lifetime under 13 minutes, single commit, focused on one concern (Active Projects strip + dormant link). The +451/-543 reflects deletion of the old card vs. addition of the strip — net negative LOC despite "feat" label.
- **Redesign indicators:** none (single commit, no reverts).
- **Planning checklist:** entry points enumerated (dormant 0-active vs. active ≥1; create-project surface preserved in both states), Performance & Cost section present and substantive.

## Code Quality Signals

- **Recurring issues:** none from review (no review). From self-reported adversarial PASS: sibling sweep was needed (3 fixtures + 1 optimistic decoration touched for new non-optional API field) — this validates the "new union member completeness" / "sibling sweep" universal convention.
- **New unrecorded patterns:** none — adding a non-optional API field requires sweeping fixtures + optimistic UI is already covered.

## Process Efficiency

- **Automation opportunities:** none new.
- **Iteration:** **efficient** — 1 commit, 12 min create-to-merge.
- **CI status:** Vercel SUCCESS, Vercel Preview Comments SUCCESS. No failures.
- **Stale-base guard:** per orchestrator note, mid-flight rebase happened when PR #620 merged; pre-push stale-base check returned 0. Both ends of the new orchestrator-protocol guard worked.

## Recommendations (ranked)

1. **Watch the recurring 4b skip pattern.** This is now the second PR (after #614) deliberately skipping CodeRabbit CLI with a similar "local critic is the gate" justification. The global rule says retry-once-then-don't-skip. If skipping continues to be net-positive across 3+ PRs without escapes, consider amending the global rule. Otherwise, enforce the retry-once contract.
2. **Self-merge with zero review is the norm in this repo at single-user scale and is acceptable, but ensure structured local-review evidence stays high quality.** PR #622's adversarial PASS evidence is exemplary — keep this bar.
3. **Step Timing remains untracked since the PR template was simplified.** If timing visibility is desired, re-add a `## Step Timing` section to `.github/PULL_REQUEST_TEMPLATE.md`. If not, accept that timing metrics will stay null going forward and stop expecting them in the dashboard.
4. **Stale-base guard worked end-to-end.** No action — log the success and keep the guard.

## Knowledge Updates

No new patterns added — existing entries in `process-patterns.md` already cover:
- "Recommendation drift across consecutive PRs" (line 32)
- "Annotate `Steps skipped:` even on trivial fixes" (line 41)
- "PR body templates should include `## Local Review` and `## Step Timing` sections" (line 125) — note: current template omits Step Timing; pattern is aspirational, not enforced.

The 4b-skip pattern is on its second occurrence; will promote to a tracked pattern at occurrence #3 per existing "promote after 3 consecutive PRs" rule.
