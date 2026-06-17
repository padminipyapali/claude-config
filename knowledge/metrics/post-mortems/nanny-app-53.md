# Post-Mortem: nanny-app PR #53 -- Fix calendar week/month total hours to include paid PTO

**Branch:** fix/calendar-total-includes-pto -> main | **Author:** padminipyapali | **Duration:** 1.20 hours
**Size:** +358 -4 across 6 files, 1 squashed commit
**Date merged:** 2026-06-16T21:34:11Z
**Merge commit:** 86e2a0aabcd9fb111c9167a3d858244274b8746d

## Summary of the change

In the Calendar view, the week and month summaries displayed a total-hours figure that summed *worked* time entries only, while the adjacent dollar amount was computed from `buildPaidEntries` (worked + paid PTO, excluding `unpaid_off`). The two reductions ran over different arrays, so the displayed number disagreed with the money beside it by exactly the paid-PTO hours. Repro: nanny "Shelo", Week 24 -- four 10.5h worked days (42h) plus an 8h paid vacation day -- showed 42.0h beside a $2,150 amount actually based on 50h ($2,150 / 50h = $43.00/h). The fix derives the displayed `totalHours` in `src/features/calendar/useCalendarData.ts` from the same paid-entry set the pay uses, in both the week aggregation and the month `stats`, so hours and pay can never diverge. `buildPaidEntries` and the pay calc are unchanged. The month total derives its paid holidays via the existing `deriveHolidaySpecialDays` helper over the month bounds, matching the week.

## LOCAL REVIEW (pre-push)

The PR body does not contain the standard `## Local Review` subsection in the format the post-mortem skill consumes (no CodeRabbit findings count, no adversarial findings count, no `Steps skipped:` line, no `## Step Timing` section). Per skill spec, `localReview`, `stepCompliance`, and `stepTiming` are recorded as `null` -- "not tracked," distinct from "tracked, zero findings."

**Side-channel evidence (from orchestrator context, not the PR body):** The change was developed via the 3-role orchestrator/implementer/critic pattern. The critic returned a SHIP verdict with **zero must-fix defects**, and a separate adversarial review found **NO issues**, before merge. This differs from PR #51, where the critic caught a real HIGH defect (giving a measured `adversarialCatchRate` of 1.0). Here, no defect was surfaced at any local gate, so there is nothing to compute a catch rate *from*: 0 defects caught out of 0 defects surfaced. `adversarialCatchRate` is recorded as `"n/a -- no defects surfaced"` rather than a fabricated `1.0` or a misleading `0.0`, consistent with the metric-integrity rule in global CLAUDE.md. A clean first-pass implementation is a distinct signal from "the reviewer caught everything"; recording it as 1.0 would falsely credit the review gate.

## STEP COMPLIANCE

- **Steps run:** null (cannot be parsed from the PR body in the expected format)
- **Compliance rate:** null
- **Note:** Same gap flagged in the PR #42, #49, and #51 post-mortems -- the nanny-app PR template still omits Local Review, Step Compliance, Step Timing, and Performance & Cost Impact sections. Fourth consecutive nanny-app PR where step adherence cannot be evaluated from durable artifacts.

## STEP TIMING

Not tracked (no `## Step Timing` section in the PR body).

## REVIEW FRICTION (post-push)

- **Review rounds:** 1 (no GitHub PR reviews, no `CHANGES_REQUESTED`, no inline comments)
- **Comments:** 0 substantive. 1 issue comment (Vercel bot deployment-skip notice, non-substantive, excluded).
- **Categories:** all zero -- nothing was flagged post-push.
- **Timeline:**
  - Created -> merged: 1.20 hours (created 20:22 UTC, merged 21:34 UTC same day)
  - First review -> merge: n/a (no reviews)
- **Self-merge:** Yes (padminipyapali squash-merged their own PR). No peer reviewer. CI (Vercel, ignored deployment) was the only external gate; the local critic + adversarial review were the substantive gates. No CodeRabbit GitHub bot review -- consistent with the trend from PRs #42, #49, #51.

## ADVERSARIAL REVIEW EFFECTIVENESS

### Pre-push catch potential: n/a -- no defects surfaced

The critic returned SHIP with no must-fixes and the adversarial review found nothing to act on, so no local defect entered the fix-up pipeline. Zero post-push findings means the post-push side is also empty. Both numerator and denominator of a catch rate are zero. This is recorded as `"n/a -- no defects surfaced"` -- a clean first-pass change -- rather than fabricating 1.0 (which would falsely credit the reviewer) or 0.0 (which would falsely imply an escape).

### Fix commits: 0 of 1 total (0% fix-up ratio)

Single squashed commit. The squash collapses any pre-merge structure into one, so feature vs. fix-up cannot be recovered from merged history. `postMergeFixRate` is 0.0 (no follow-up fix PRs touching `useCalendarData.ts` / the Calendar within 48h as of this analysis).

## PLANNING QUALITY: complete

- **Problem:** Present and excellent -- a concrete worked table (42h worked + 8h vacation = 50h; $2,150 / 50h = $43.00/h) quantifying the exact divergence.
- **Root cause:** Present -- names the two divergent reductions (`weekEntries.reduce` / `monthEntries.reduce` worked-only vs. `buildPaidEntries` for pay) and why the bug was Calendar-only (the Hours tab already used the paid basis).
- **Fix:** Present -- derive `totalHours` from the same paid-entry set, in both week and month-stats aggregations.
- **Known limitation:** Present -- documents that `buildPaidEntries` does not dedup a date with both a worked entry and a paid special day; pre-existing, intentionally unchanged, recorded in code + bugs.md.
- **Sibling sweep:** Present and explicit -- Dashboard, PaySummary, PDF export, Hours tab, `calculatePayPeriod` all checked and confirmed already consistent.
- **Testing:** Present -- 6 tests (50h repro + equality with pay basis, `unpaid_off` exclusion week/month, month worked+vacation+derived-holiday, sick-day inclusion, holiday-also-paid-holiday dedup).
- **Docs:** Present -- bugs.md (+25), product-spec.md changelog (+1), version bump 0.0.6 -> 0.0.7.
- **Missing:** No "Performance & Cost Impact" section (required by global CLAUDE.md). Low impact (pure local computation over an already-built entry set, no new reads/writes), but the section should still be present and say so.
- **Scope:** Clean, single coherent bug fix. Branch lifetime 1.2 hours. 362 LOC, comfortably under the 600 LOC guideline (301 of the additions are the test file).

## CODE QUALITY SIGNALS

- **Recurring issues:** None observable -- zero post-push comments.
- **Same-basis derivation (positive).** The fix unifies the *input* array (both display and pay reduce over `buildPaidEntries`) rather than reconciling two outputs. Eliminates the bug class at the root: they cannot drift because they share a source. The durable lesson: when a displayed number and its adjacent money come from two reductions, unify the input.
- **Proactive sibling sweep (positive).** Every total that sums `.hours` was checked before declaring done; the Calendar was the lone offender. This is the "pattern siblings" discipline #26 had to be corrected for in review, applied up front -- carryover strength from #49 and #51.
- **Honest known-limitation note (positive).** The pre-existing no-dedup behavior of `buildPaidEntries` was documented rather than silently inherited or quietly "fixed" with scope creep.
- **New unrecorded patterns:** The displayed-number/derived-money divergence pattern (below) is worth capturing cross-project. The squash-merge metric gap is already documented (#42, #49).

## PROCESS EFFICIENCY

- **CI status:** All passed (`npm run build` + 230 unit tests reported in body; Vercel deployment ignored).
- **Iteration:** 0 rounds of post-push review. Clean merge.
- **Automation opportunities:** None lint-catchable -- the divergence was a semantic mismatch between two correct-looking reductions, not a syntactic defect.
- **Time-to-merge:** 1.2 hours -- fast, clean single-pass change.

## KNOWLEDGE UPDATES

- **New cross-project pattern (capture candidate): displayed-number / derived-money divergence.** When a number shown to the user and the money quoted beside it are each produced by reducing over a *separate* collection, they drift whenever the two collections differ. The fix is to make both reductions consume the same source array, not to reconcile their outputs. Confidence that the fix is complete comes from a sibling sweep across every surface performing the same kind of reduction. (Belongs in `~/.claude/knowledge/` -- handled outside this repo / by the orchestrator; not edited here.)
- No `adversarial-review.md` update -- zero post-push findings means no missed checks to add.
- The recurring "nanny-app PR template lacks Local Review / Step Compliance / Step Timing / Performance & Cost sections" finding is a *process* gap already recorded against #42, #49, #51; this PR is a fourth data point.

## RECOMMENDATIONS

1. **Adopt the standardized nanny-app PR template.** Fourth consecutive nanny-app PR (after #42, #49, #51) whose `localReview` / `stepCompliance` / `stepTiming` are unmeasurable purely because the body lacks those sections. A structured `## Local Review` block would let "0 defects, clean first pass" be a parsed metric instead of a prose inference.
2. **Add a "Performance & Cost Impact" section even when impact is nil.** A one-line "pure local computation over an already-built entry set, no new reads/writes" satisfies the rule and proves it was considered.
3. **Decide CodeRabbit-on-GitHub policy for nanny-app.** PRs 26-35 had GitHub reviews; 42, 49, 51, 53 did not. Commit to CLI-only at Step 4b or re-enable the bot so friction metrics stop being noisy.
4. **Acknowledge the squash-merge metric gap (carryover).** `fixupCommitRatio` and the fix-up taxonomy are 0 by construction for every squash-merged nanny-app PR.
