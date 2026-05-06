# Post-Mortem: second-brain PR #618

**Title:** chore(web): remove redundant PROJECTS filter chip from Recent Entries
**Branch:** chore/remove-projects-chip → main | **Author:** padminipyapali
**Created → Merged:** 2026-05-06 14:37 → 16:27 UTC (~1h50m)
**Size:** +30 −196 across 3 files, 2 commits | **Closes:** #617

## Local Review
Not tracked in PR body (no `## Local Review` section).

## Step Compliance
Not tracked.

## Step Timing
Not tracked.

## Review Friction (post-push)
- Reviews: 0 (self-merged, no peer review).
- Inline comments: 0. General comments: 1 (vercel bot — excluded).
- Timeline: created → merged ≈ 1.82h, no human review event.

## Adversarial Review Effectiveness
- No post-push findings to attribute. Pre-push catch potential: n/a.
- `adversarialCatchRate`: unmeasured (no review evidence).

## Fix-up Metrics
- Commits: 2 — one feature (`chore(web): remove redundant Projects filter chip`), one fix (`test(web): restore scroll-into-view regression test for #612`).
- The "restore" commit indicates the implementation initially dropped a regression test that needed to be added back — caught during local internal review (pre-push). Attributed to step 4b.
- `postMergeFixRate`: 0% (no follow-ups within 48h window so far).
- `preMergeIterationCount`: 1 (healthy for a delete-only PR).
- Fix-up taxonomy: { test-quality: 1 } — restoring a guard test for an existing regression.
- Legacy `fixupCommitRatio`: 50% (1/2). Inflated by small denominator; not a quality concern given the nature of the fix.

## Planning Quality
- Description: complete (Summary, Test plan, Out of scope, Notes).
- Scope: clean — single concern (remove redundant chip), branch lifetime ~2h, −166 net LOC.
- No Performance & Cost section, but this is a deletion-only chore — n/a.

## Code Quality Signals
- Recurring issues: none.
- New unrecorded patterns: none.
- Notable: explicit `Out of scope` callout (deferring COMPLETED/ARCHIVED archive surface) and explicit acknowledgement of pre-existing test failures unrelated to the PR. Good signal hygiene.

## Process Efficiency
- CI status: not captured per-check; PR body notes pre-existing failures unrelated to this change.
- Iteration: efficient (1 round, self-served).
- Automation opportunities: none specific.

## Knowledge Updates
- No new patterns to capture. The "delete duplicated UI surface, preserve regression test" workflow is already well-trodden.

## Recommendations
1. Self-merge with no human review is recurring across recent PRs; if a teammate exists, consider routing chores through a lightweight review. Otherwise this is by design for a solo dev — no action needed.
2. When deleting a component file alongside its tests, do a deliberate sweep for regression tests that should be preserved — would have avoided the second commit (caught here, but a checklist item could prevent the round-trip).
