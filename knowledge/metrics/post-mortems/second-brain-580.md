# POST-MORTEM: second-brain PR #580 — fix(projects): faster sub-task add + correct row layout

Branch: fix/projects-subtask-perf-layout -> main | Author: padminipyapali | 0.05h (3 minutes)
Size: +580 -35 across 13 files, 1 commit. Self-merged, no reviews.

## Local Review / Step Compliance / Step Timing
Not tracked. PR body has no `## Local Review` section, no `Steps skipped:` line, no `## Step Timing` table. Shift-left rate and step compliance cannot be computed.

## Review Friction (post-push)
- Review rounds: 1 (no CHANGES_REQUESTED)
- Comments: 0 substantive (1 Vercel bot comment, excluded)
- Timeline: created -> merged ~3 minutes. Self-merged.

## Adversarial Review Effectiveness
No post-push comments -> catch-rate unmeasured. PR test plan has three unchecked `[ ]` items (long sub-task wrap, foreign-user 404, mid-add project deletion warning).

## Fix-up Metrics
- Post-merge fix rate: 0.0 (no follow-ups yet)
- Pre-merge catch rate by step: all 0 (single commit)
- Pre-merge iteration count: 1
- Legacy fix-up ratio: 0/1 = 0%

## Planning Quality
Complete description: Summary, atomicity rationale, both bugs, test plan, baseline failures. Branch lifetime <1 hour. Performance captured ("1 RTT, no Claude call"). Entry points enumerated implicitly.

## Code Quality Signals
No recurring issues observable. No new patterns; PR reinforces existing atomicity guidance.

## Process Efficiency
Iteration efficient (1 round). PR body lists three pre-existing baseline failures shipped around, not new regressions.

## Concerns
- Self-merge with no review at 580 LOC, near the 600 LOC cap.
- Missing `## Local Review` section: no evidence the Step 4 gate ran.
- Three `[ ]` test-plan items merged unchecked.
- Pre-existing baseline failures (Lightbox a11y, EntryCard ResizeObserver, MessageProcessor reminder, getRelatedEntries embedding equality) keep being carried forward.

## Recommendations
1. Fix the orchestrator template so `## Local Review` and `Steps skipped:` are always emitted.
2. Triage the four pre-existing baseline failures into GitHub issues.
3. Execute or remove unchecked test-plan items before merge.

## Knowledge Updates
None added.
