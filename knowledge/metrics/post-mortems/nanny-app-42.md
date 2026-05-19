# Post-Mortem: nanny-app PR #42 -- feat: add per-nanny paid holidays

**Branch:** feat/paid-holidays-per-nanny -> main | **Author:** padminipyapali | **Duration:** 12.39 hours
**Size:** +918 -56 across 18 files, 1 squashed commit
**Date merged:** 2026-05-18T18:36:14Z
**Merge commit:** 3a4d19d68fe3384ebe5cfa5007c3c37f0132cd2c

## LOCAL REVIEW (pre-push)

PR description does not include the standard "Local Review" subsection in the format the post-mortem skill consumes. Per skill spec, localReview/stepCompliance/stepTiming are recorded as `null`.

**Side-channel evidence (from orchestrator context, not PR body):** The change was developed via the 3-role orchestrator/implementer/critic pattern with TWO adversarial critic passes locally before push. CodeRabbit CLI (Step 4b) was either not run or not captured in the PR body. No structured local-review findings can be counted, so `adversarialCatchRate` is recorded as `"unmeasured"` rather than fabricated -- consistent with the post-mortem metric-integrity rule in global CLAUDE.md.

## STEP COMPLIANCE

- **Steps run:** null (cannot be parsed from PR body in the expected format)
- **Compliance rate:** null
- **Note:** The PR body has Summary + PR size note + Test plan but no Step Compliance section. Step adherence cannot be evaluated from artifacts. Action item: standardize the PR template across nanny-app so every PR carries Local Review, Step Compliance, and Step Timing sections.

## REVIEW FRICTION (post-push)

- **Review rounds:** 0 (no GitHub PR reviews, no inline comments)
- **Comments:** 1 issue comment (vercel bot deployment skip notice, non-substantive)
- **Categories:** all zero -- nothing was flagged post-push
- **Timeline:**
  - Created -> merged: 12.39 hours (created 06:12 UTC, merged 18:36 UTC same day)
  - First review -> merge: n/a (no reviews)
- **Self-merge:** Yes (padminipyapali squash-merged their own PR). No peer reviewer; CI (2/2) was the only external gate.

## ADVERSARIAL REVIEW EFFECTIVENESS

### Pre-push catch potential: unmeasured

Zero post-push findings means the post-push side of the catch-rate equation is empty. We cannot derive a meaningful catch rate from a divisor of zero. For this PR the local two-pass adversarial review either:
(a) caught everything that would have been flagged, or
(b) was sufficient *because* there was no external reviewer to flag anything (no peer review, no CodeRabbit GitHub bot comments posted, no human review).

Both interpretations are consistent with the evidence; we cannot disambiguate. Marking as `"unmeasured"` rather than `1.0` keeps the dataset honest. (Hardcoded `1.0` values were the bug the metric-integrity rule was added to prevent.)

### Fix commits: 0 of 1 total (0% fix-up ratio)

Single squashed commit -- the squash merge collapses any pre-merge fix-up commits on the branch into one. From the merged history we cannot distinguish "feature commit" from "fix-up commits" because git only retains the squashed result.

## PLANNING QUALITY: partial

- **Summary:** Present, detailed, lists all surfaces touched (calendar, days-off, hours-tracker, dashboard, pay-summary, PDF).
- **Test plan:** Present, 11 checklist items covering settings, calendar, hours tracker (current + past), holiday-only past period, PDF, dashboard, pay summary, days-off list, override precedence, and edge cases.
- **PR size note:** Present and self-aware (974 LOC vs 600 LOC guideline) with justification (340 LOC of tests, single coherent feature, multiple required call sites).
- **Missing sections:**
  - No "Local Review" section (CodeRabbit findings + adversarial findings counts/iterations)
  - No "Step Compliance" section
  - No "Step Timing" section
  - No "Performance & Cost Impact" section (required by global CLAUDE.md planning rules)
- **Scope:** Clean, single coherent feature.
- **Branch lifetime:** 12.4 hours.

## CODE QUALITY SIGNALS

- **Recurring issues:** None observable -- zero post-push comments.
- **Fix-up ratio:** 0% (single squashed commit; cannot decompose).
- **PR size:** 974 LOC, **62% above the 600 LOC guideline.** Justification was given in the PR body and is reasonable. Pattern worth watching: features that touch settings + calendar + hours tracker + dashboard + PDF simultaneously will reliably blow the 600 LOC budget.
- **New unrecorded patterns:**
  - **Squash merges hide fix-up structure.** When a project squash-merges by default, the merged commit history loses signal needed for fix-up taxonomy. The metric `fixupCommitRatio` becomes 0 by construction for every squash-merged PR. Systemic gap in the metrics pipeline.

## PROCESS EFFICIENCY

- **CI status:** 2/2 checks passed.
- **Iteration:** 0 rounds of post-push review. Either excellent local review *or* insufficient external review gate. Prior nanny-app PRs (28, 29, 33, 35) all received CodeRabbit GitHub reviews; this one did not. Cannot disambiguate.
- **Time-to-merge:** 12.4 hours -- created early morning, merged after a workday. Consistent with "wait for CI, then merge" rather than "wait for review."

## KNOWLEDGE UPDATES

No new cross-project patterns observed that aren't already captured. No update to `adversarial-review.md` -- zero post-push findings means no missed checks to add.

## RECOMMENDATIONS

1. **Standardize the nanny-app PR template** to include Local Review, Step Compliance, Step Timing, and Performance & Cost Impact sections.
2. **Decide whether to re-enable CodeRabbit GitHub bot reviews on nanny-app PRs**, or commit to "CLI-only" CodeRabbit at Step 4b. Inconsistency makes friction metrics noisy.
3. **Acknowledge the squash-merge metric gap.** Either capture pre-squash branch history into post-mortems, or drop `fixupCommitRatio` from squash-merged-project comparisons.
4. **PR size watch.** 974 LOC for a multi-surface feature is acceptable here but the justification will recur. Consider splitting the next multi-surface feature along the derivation/UI boundary to stay under 600.
