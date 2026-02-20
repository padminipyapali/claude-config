# Post-Mortem: second-brain PR #189 — Fix broken media images on web dashboard

**Branch:** fix/broken-media-images -> main | **Author:** padminipyapali | **0.34 hours**
**Size:** +138 -2 across 4 files, 1 commit

## LOCAL REVIEW (pre-push)

- CodeRabbit: not run locally (skipped)
- Adversarial: not run locally (skipped)
- Internal review: 0 findings (informal — noted in PR body but step formally skipped)
- Shift-left rate: 0% (1 post-push finding, 0 pre-push catches)

## STEP COMPLIANCE

- Steps run: 1, 2, 3, 5 (4/8)
- Steps skipped: 4a (simplification), 4b (internal review), 4c (CodeRabbit), 4d (adversarial) — reason: "production diff is 11 LOC, under 50 threshold; user approved plan"
- Compliance rate: 50%
- Skip assessment: bad — CodeRabbit found a correctness issue (stale imageError state) post-push that step 4c would have caught. Low severity for this specific PR (only 2 MEDIA entries, no dynamic swapping), but the pattern is real.

## REVIEW FRICTION (post-push)

- Review rounds: 1 (0 CHANGES_REQUESTED, CodeRabbit COMMENTED + APPROVED)
- Comments: 0 inline, 2 general (both bot: 1 Vercel deployment, 1 CodeRabbit walkthrough)
- Substantive findings: 1 (CodeRabbit review body: stale imageError state when component reused with different props)
- Categories: { correctness: 1 }
- Timeline: created -> first review: ~5min | first review -> merge: ~15min | total: 20min
- Self-merge with bot-only review

## ADVERSARIAL REVIEW EFFECTIVENESS

- Pre-push catch potential: 100% (1 finding, 1 was a known pattern)
- Covered but missed: stale useState when component reused — maps to existing react-patterns.md "stale closure/state" patterns and adversarial-review.md stale state checks
- Not covered (new categories): none
- Fix commits: 0 of 1 total (0% fix-up ratio)

## PLANNING QUALITY

- Description: complete (Summary, Context, Test Plan, Local Review sections)
- Scope: clean (4 files, focused bug fix + defensive improvements)
- Branch lifetime: 20 minutes
- Planning checklist: partial — plan was done in plan mode with adversarial plan review, but performance/cost section was implicit (no new API calls, minimal CPU impact)

## CODE QUALITY SIGNALS

- Recurring issues: none
- Fix-up ratio: 0%
- New unrecorded patterns: none — the stale state pattern is already documented

## PROCESS EFFICIENCY

- Automation opportunities: none (the finding was about React state semantics, not mechanical)
- Iteration: efficient (1 round, auto-approved, merged in 20 minutes)
- CI status: all passed (CodeRabbit SUCCESS, Vercel SUCCESS)

## KNOWLEDGE UPDATES

- No new patterns to add — stale useState on prop change is already in react-patterns.md
- process-patterns.md: add note about LOC threshold skip assessment

## RECOMMENDATIONS

1. **The 50 LOC skip threshold is imperfect.** 11 LOC of production code, but CodeRabbit still found a valid correctness issue. The threshold measures diff size, not complexity. A useState + conditional render change has more semantic surface than 11 LOC suggests. Consider: when a diff introduces React state hooks, run at least 4c (CodeRabbit) regardless of LOC.
2. **CodeRabbit finding is valid but low-priority for THIS PR.** The stale imageError scenario requires: (a) same EntryMedia instance reused for different entries, (b) first entry's image fails, (c) second entry has a valid image. With React keys on entry cards, this is unlikely in the current UI. Worth fixing in a follow-up but not a blocker.
3. **Playwright testing was done manually after PR creation** — confirmed both MEDIA entries show "Image not available" placeholder. This was valuable but happened post-push. In future, Playwright should run as part of Step 3.
