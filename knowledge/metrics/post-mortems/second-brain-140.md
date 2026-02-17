# Post-Mortem: second-brain PR #140 — Fix stale closure race condition in useEntries

**Branch:** fix/stale-closure-useentries → main | **Author:** padminipyapali | **Duration:** 2.25h
**Size:** +24 -5 across 1 file, 2 commits | **Merged:** 2026-02-17T03:23:57Z

## Context

This PR fixes a race condition in the `useEntries` hook where rapid tab/filter switching could cause a background fetch from a previous tab to overwrite the current tab's state. Adds a `currentKeyRef` staleness guard and `isMountedRef` unmount guard.

## Local Review (pre-push)

- **CodeRabbit:** 0 findings on PR files (1 pre-existing suggestion on unrelated file), 1 iteration
- **Adversarial review:** 0 findings
- **CI status:** all passed
- **Shift-left rate:** 0% — the one real issue was missed locally

## Review Friction (post-push)

- **Review rounds:** 2 (1 CHANGES_REQUESTED → 1 APPROVED)
- **Comments:** 1 inline (CodeRabbit bot)
- **Categories:** correctness: 1
- **Timeline:** created → first review: 3min | first review → approval: 1.6h | approval → merge: 37min | total: 2.25h
- **Self-merge:** Yes, with bot review only (no human reviewer)

## Adversarial Review Effectiveness

- **Pre-push catch potential:** 0% (0 of 1 issues caught)
- **Covered but missed:** Unmount guard pattern — already documented in `react-patterns.md` ("Unmount guard on async fetches — two patterns") AND used by 3 sibling hooks in the same file (useThread, useRelatedEntries, useThreadSummary). The adversarial review should have caught this via "pattern siblings" check.
- **Not covered (new categories):** None — this was an execution gap, not a checklist gap.
- **Fix commits:** 1 of 2 total (50% fix-up ratio)

## Planning Quality

- **Description:** Complete (Summary + Test Plan sections)
- **Scope:** Clean — 1 file, 29 LOC, single concern
- **Branch lifetime:** 2.25 hours
- **Planning checklist:** N/A for small bug fix

## Code Quality Signals

- **Recurring issues:** None (single comment)
- **Fix-up ratio:** 50% (1 fix / 2 total commits) — high ratio but contextually expected on a 2-commit small PR
- **New unrecorded patterns:** The `useCallback` + `useRef` unmount guard variant was already strengthened in react-patterns.md during the review-fix step

## Process Efficiency

- **Automation opportunities:** The adversarial review checklist already includes "pattern siblings" as a universal check. The gap was execution: the review didn't compare the new `useEntries` async patterns against sibling hooks in the same file.
- **Iteration:** Normal (2 rounds, 1 fix commit, all mechanical)
- **CI:** All passed (CodeRabbit SUCCESS, Vercel SUCCESS)

## Knowledge Updates

| File | Action | Entry |
|------|--------|-------|
| `react-patterns.md` | Strengthened | "Unmount guard on async fetches — two patterns" — added useCallback+useRef variant |
| `process-patterns.md` | Added | "Unmount guard pattern known but not applied to new code" — adversarial review gap |
| `process-patterns.md` | Added | "50% fix-up ratio on small focused PR" — context note on ratio interpretation |
| `post-mortem-metrics.json` | Added | PR #140 entry |
| `dashboard.html` | Regenerated | Updated with 123 total PRs |

## Recommendations

1. **Adversarial review: mechanically check sibling patterns.** When reviewing a hook or function with async patterns, grep the same file for similar hooks and verify the new code uses the same defensive patterns. This was literally the "pattern siblings" universal check but wasn't applied intra-file.
2. **Small PR ratio interpretation.** On PRs with 2-3 commits, a single review fix creates 33-50% fix-up ratio. Don't weight these the same as high ratios on large PRs with many commits.
